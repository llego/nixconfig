{
  config,
  pkgs,
  ...
}: let
  oura-report = pkgs.writeShellApplication {
    name = "oura-health-report";
    runtimeInputs = with pkgs; [curl jq coreutils];
    text = ''
      TODAY=$(date +%Y-%m-%d)
      WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%d)

      fetch() {
        curl -sf \
          -H "Authorization: Bearer ''${OURA_PAT}" \
          "https://api.ouraring.com/v2/usercollection/''${1}?start_date=''${WEEK_AGO}&end_date=''${TODAY}"
      }

      SLEEP=$(fetch daily_sleep)
      ACTIVITY=$(fetch daily_activity)
      READINESS=$(fetch daily_readiness)

      fmt_sleep() {
        echo "''${SLEEP}" | jq -r '
          .data[] |
          "  " + .day +
          ": score=" + (.score // 0 | tostring) +
          ", deep=" + (.contributors.deep_sleep // 0 | tostring) +
          ", rem=" + (.contributors.rem_sleep // 0 | tostring) +
          ", total=" + (.contributors.total_sleep // 0 | tostring)
        ' 2>/dev/null || echo "  no data"
      }

      fmt_activity() {
        echo "''${ACTIVITY}" | jq -r '
          .data[] |
          "  " + .day +
          ": score=" + (.score // 0 | tostring) +
          ", steps=" + (.steps // 0 | tostring) +
          ", active_cal=" + (.active_calories // 0 | tostring)
        ' 2>/dev/null || echo "  no data"
      }

      fmt_readiness() {
        echo "''${READINESS}" | jq -r '
          .data[] |
          "  " + .day +
          ": score=" + (.score // 0 | tostring) +
          ", hrv=" + (.contributors.hrv_balance // 0 | tostring) +
          ", recovery=" + (.contributors.recovery_index // 0 | tostring) +
          ", rhr=" + (.contributors.resting_heart_rate // 0 | tostring)
        ' 2>/dev/null || echo "  no data"
      }

      DATA="Oura Ring data (''${WEEK_AGO} -> ''${TODAY})

      Sleep (score, deep%, rem%, total%):
      $(fmt_sleep)

      Activity (score, steps, active_cal):
      $(fmt_activity)

      Readiness (score, hrv%, recovery%, rhr%):
      $(fmt_readiness)"

      # Write biometric data to USER.md so hermes auto-injects it into every conversation.
      USER_MD=/var/lib/hermes/.hermes/USER.md
      cat > "$USER_MD" <<USERMD
# Biometric Data (Oura Ring)

Last updated: ''${TODAY}
Data range: ''${WEEK_AGO} → ''${TODAY}

## Sleep (score, deep%, rem%, total%)
$(fmt_sleep)

## Activity (score, steps, active_calories)
$(fmt_activity)

## Readiness (score, hrv_balance%, recovery_index%, resting_heart_rate%)
$(fmt_readiness)
USERMD
      chmod 0640 "$USER_MD"

      RESPONSE=$(curl -sf \
        -H "Authorization: Bearer ''${OPENROUTER_API_KEY}" \
        -H "content-type: application/json" \
        "https://openrouter.ai/api/v1/chat/completions" \
        -d "$(jq -n \
          --arg data "''${DATA}" \
          '{
            model: "anthropic/claude-haiku-4-5",
            max_tokens: 600,
            messages: [
              {role: "system", content: "You are a concise health coach. Analyze Oura Ring biometric data and provide: (1) 2-sentence trend summary, (2) top win of the week, (3) top 2 improvements for next week. Plain text, no markdown."},
              {role: "user", content: $data}
            ]
          }')")

      REPORT=$(echo "''${RESPONSE}" | jq -r '.choices[0].message.content // "Report generation failed."')

      curl -sf -X POST \
        "https://api.telegram.org/bot''${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -H "Content-Type: application/json" \
        -d "$(jq -n \
          --arg chat_id "''${TELEGRAM_HOME_CHANNEL}" \
          --arg thread_id "''${TELEGRAM_CRON_THREAD_ID}" \
          --arg msg "Health Report (''${TODAY})

      ''${REPORT}

      ---
      ''${DATA}" \
          '{chat_id: $chat_id, message_thread_id: ($thread_id | tonumber), text: $msg}')"
    '';
  };
in {
  environment.systemPackages = [oura-report];

  # Daily Oura Ring health report delivered to the Telegram health topic at 08:00.
  # Requires OURA_PAT, TELEGRAM_BOT_TOKEN, TELEGRAM_HOME_CHANNEL, and
  # TELEGRAM_CRON_THREAD_ID in secrets/hermes-env.age.
  systemd.services.oura-health-report = {
    description = "Fetch Oura Ring data and send daily health report via Telegram";
    after = ["network-online.target"];
    requires = ["network-online.target"];
    unitConfig.ConditionPathExists = config.age.secrets.hermes-env.path;
    serviceConfig = {
      Type = "oneshot";
      User = "hermes";
      Group = "hermes";
      EnvironmentFile = config.age.secrets.hermes-env.path;
      ExecStart = "${oura-report}/bin/oura-health-report";
    };
  };

  systemd.timers.oura-health-report = {
    description = "Daily Oura Ring health report at 08:00";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 08:00:00";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };
}
