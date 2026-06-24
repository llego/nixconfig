{
  config,
  pkgs,
  ...
}: let
  importer = pkgs.writers.writePython3Bin "yle-bluey-sonarr-import" {} ''
    import json
    import os
    import re
    import subprocess
    import time
    import unicodedata
    import urllib.request
    import xml.etree.ElementTree as ET
    from pathlib import Path

    SERIES_URL = "https://areena.yle.fi/1-66393054"
    SERIES_ID = 159
    SERIES_TITLE = "Bluey (2018)"
    STATE_DIR = Path("/var/lib/yle-sonarr-import/bluey-2018")
    HOST_DOWNLOAD_DIR = Path(
        "/mnt/illby/transient/sabnzbd-downloads/yle-dl/bluey-2018"
    )
    SONARR_DOWNLOAD_DIR = "/downloads/yle-dl/bluey-2018"
    SONARR_URL = "http://localhost:8989"
    SONARR_CONFIG = Path("/mnt/illby/docker/data/sonarr/config.xml")
    GOTIFY_URL = "https://gotify.cri.su/message"
    OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
    OPENROUTER_MODEL = os.environ.get(
        "OPENROUTER_MODEL",
        "anthropic/claude-haiku-4-5",
    )

    DEFAULT_MAPPING = {
        "tuuri: hotelli": {"season": 1, "episode": 10},
        "tuuri: pyorailya": {"season": 1, "episode": 11},
        "tuuri: kopi kani": {"season": 1, "episode": 12},
        "tuuri: vaari": {"season": 2, "episode": 27},
        "tuuri: roskapontot": {"season": 2, "episode": 42},
        "tuuri: ankkakakku": {"season": 2, "episode": 44},
        "tuuri: kasillaseisonta": {"season": 2, "episode": 45},
        "tuuri: automatka": {"season": 2, "episode": 46},
        "tuuri: jaatelo": {"season": 2, "episode": 47},
        "tuuri: huussi": {"season": 2, "episode": 48},
        "tuuri: kirjoituskone": {"season": 2, "episode": 49},
    }


    def log(message):
        print(message, flush=True)


    def read_json(path, default):
        if not path.exists():
            return default
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle)


    def write_json(path, data):
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_suffix(path.suffix + ".tmp")
        with tmp.open("w", encoding="utf-8") as handle:
            json.dump(data, handle, ensure_ascii=False, indent=2, sort_keys=True)
            handle.write("\n")
        tmp.replace(path)


    def normalize(text):
        text = unicodedata.normalize("NFKD", text or "")
        text = "".join(char for char in text if not unicodedata.combining(char))
        text = text.lower().strip()
        text = re.sub(r"\s+", " ", text)
        return text


    def safe_filename(text):
        text = re.sub(r"[\\/:*?\"<>|]", " ", text)
        text = re.sub(r"\s+", " ", text).strip()
        return text


    def utc_now():
        return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


    def http_json(method, url, headers=None, body=None, timeout=30):
        data = None
        final_headers = {"Accept": "application/json"}
        if headers:
            final_headers.update(headers)
        if body is not None:
            data = json.dumps(body).encode("utf-8")
            final_headers["Content-Type"] = "application/json"
        request = urllib.request.Request(
            url,
            data=data,
            headers=final_headers,
            method=method,
        )
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = response.read().decode("utf-8")
            if not payload:
                return None
            return json.loads(payload)


    def gotify(title, message, priority=2):
        token = os.environ.get("GOTIFY_APP_TOKEN")
        if not token:
            log("Gotify token not configured; skipping notification")
            return
        try:
            http_json(
                "POST",
                GOTIFY_URL,
                headers={"X-Gotify-Key": token},
                body={"title": title, "message": message, "priority": priority},
                timeout=15,
            )
        except Exception as exc:
            log(f"Gotify notification failed: {exc}")


    def sonarr_api_key():
        root = ET.parse(SONARR_CONFIG).getroot()
        api_key = root.findtext("ApiKey")
        if not api_key:
            raise RuntimeError(f"No ApiKey found in {SONARR_CONFIG}")
        return api_key


    def sonarr_get(path, api_key):
        return http_json(
            "GET",
            f"{SONARR_URL}{path}",
            headers={"X-Api-Key": api_key},
        )


    def sonarr_post(path, api_key, body):
        return http_json(
            "POST",
            f"{SONARR_URL}{path}",
            headers={"X-Api-Key": api_key},
            body=body,
        )


    def fetch_sonarr_episodes(api_key):
        episodes = sonarr_get(f"/api/v3/episode?seriesId={SERIES_ID}", api_key)
        by_number = {}
        for episode in episodes:
            episode_key = (episode["seasonNumber"], episode["episodeNumber"])
            by_number[episode_key] = episode
        return episodes, by_number


    def fetch_yle_metadata():
        result = subprocess.run(
            ["yle-dl", SERIES_URL, "--showmetadata"],
            check=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        return json.loads(result.stdout)


    def download_episode(item, target):
        tmp = target.with_name(f".{item['program_id']}.partial{target.suffix}")
        if tmp.exists():
            tmp.unlink()
        subprocess.run(
            [
                "yle-dl",
                item["webpage"],
                "--resolution",
                "1080",
                "--sublang",
                "none",
                "--no-overwrite",
                "-o",
                str(tmp),
            ],
            check=True,
        )
        tmp.replace(target)


    def trigger_sonarr_import(api_key):
        command = sonarr_post(
            "/api/v3/command",
            api_key,
            {"name": "DownloadedEpisodesScan", "path": SONARR_DOWNLOAD_DIR},
        )
        return command.get("id") if isinstance(command, dict) else None


    def ai_suggest(item, episodes):
        api_key = os.environ.get("OPENROUTER_API_KEY")
        if not api_key:
            return {
                "status": "ai_unavailable",
                "reason": "OPENROUTER_API_KEY is not configured",
            }

        candidates = [
            {
                "season": episode["seasonNumber"],
                "episode": episode["episodeNumber"],
                "title": episode["title"],
                "airDate": episode.get("airDate"),
                "hasFile": episode.get("hasFile"),
                "monitored": episode.get("monitored"),
            }
            for episode in episodes
            if episode.get("seasonNumber", 0) > 0 and episode.get("monitored")
        ]
        candidates.sort(
            key=lambda episode: (
                episode["hasFile"],
                episode["season"],
                episode["episode"],
            )
        )

        prompt = {
            "yle_episode": {
                "program_id": item.get("program_id"),
                "title": item.get("episode_title"),
                "description": item.get("description"),
                "publish_timestamp": item.get("publish_timestamp"),
                "duration_seconds": item.get("duration_seconds"),
            },
            "sonarr_candidates": candidates,
            "instructions": (
                "Map the Finnish-localized YLE Areena Bluey episode to "
                "exactly one provided Sonarr candidate, or return no_match. "
                "Return JSON only with keys: status, season, episode, "
                "sonarr_title, confidence, reason. Do not "
                "invent candidates. Use no_match when uncertain."
            ),
        }
        response = http_json(
            "POST",
            OPENROUTER_URL,
            headers={"Authorization": f"Bearer {api_key}"},
            body={
                "model": OPENROUTER_MODEL,
                "max_tokens": 500,
                "messages": [
                    {
                        "role": "system",
                        "content": (
                            "You match localized Finnish Bluey episode "
                            "metadata to canonical Sonarr episodes. "
                            "Return strict JSON only."
                        ),
                    },
                    {
                        "role": "user",
                        "content": json.dumps(prompt, ensure_ascii=False),
                    },
                ],
            },
            timeout=60,
        )
        content = response["choices"][0]["message"]["content"]
        content = content.strip()
        if content.startswith("```"):
            content = re.sub(r"^```(?:json)?\s*", "", content)
            content = re.sub(r"\s*```$", "", content)
        try:
            parsed = json.loads(content)
        except json.JSONDecodeError:
            parsed = {"status": "parse_error", "raw_response": content}
        return parsed


    def ensure_mapping_file(path):
        mapping = read_json(path, {})
        changed = False
        for title, value in DEFAULT_MAPPING.items():
            if title not in mapping:
                mapping[title] = value
                changed = True
        if changed or not path.exists():
            write_json(path, mapping)
        return mapping


    def main():
        STATE_DIR.mkdir(parents=True, exist_ok=True)
        HOST_DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)

        mapping_path = STATE_DIR / "mapping.json"
        state_path = STATE_DIR / "state.json"
        pending_path = STATE_DIR / "pending-suggestions.json"

        mapping = ensure_mapping_file(mapping_path)
        state = read_json(state_path, {"handled_program_ids": {}})
        pending = read_json(pending_path, {})
        handled = state.setdefault("handled_program_ids", {})

        api_key = sonarr_api_key()
        episodes, episodes_by_number = fetch_sonarr_episodes(api_key)
        metadata = fetch_yle_metadata()
        metadata.sort(key=lambda item: item.get("publish_timestamp") or "")

        imported = 0
        suggested = 0
        skipped = 0

        for item in metadata:
            program_id = item.get("program_id")
            if not program_id or program_id in handled:
                skipped += 1
                continue

            title_key = normalize(item.get("episode_title"))
            mapped = mapping.get(title_key)
            if not mapped:
                if program_id not in pending:
                    suggestion = ai_suggest(item, episodes)
                    pending[program_id] = {
                        "program_id": program_id,
                        "yle_title": item.get("episode_title"),
                        "yle_description": item.get("description"),
                        "publish_timestamp": item.get("publish_timestamp"),
                        "suggestion": suggestion,
                        "status": "needs_review",
                        "created_at": utc_now(),
                    }
                    write_json(pending_path, pending)
                    suggested += 1
                    gotify(
                        "Bluey YLE import needs mapping",
                        (
                            "New unmapped YLE episode: "
                            f"{item.get('episode_title')} ({program_id}). "
                            f"AI suggestion written to {pending_path}."
                        ),
                        priority=4,
                    )
                else:
                    skipped += 1
                continue

            season = int(mapped["season"])
            episode_number = int(mapped["episode"])
            sonarr_episode = episodes_by_number.get((season, episode_number))
            if not sonarr_episode:
                gotify(
                    "Bluey YLE import mapping error",
                    (
                        f"{item.get('episode_title')} maps to missing "
                        f"S{season:02d}E{episode_number:02d} in Sonarr."
                    ),
                    priority=5,
                )
                continue

            if sonarr_episode.get("hasFile"):
                handled[program_id] = {
                    "status": "already_present",
                    "season": season,
                    "episode": episode_number,
                    "handled_at": utc_now(),
                }
                write_json(state_path, state)
                skipped += 1
                continue

            final_name = (
                f"{SERIES_TITLE} - S{season:02d}E{episode_number:02d} - "
                f"{safe_filename(sonarr_episode['title'])} WEB-DL-1080p.mkv"
            )
            target = HOST_DOWNLOAD_DIR / final_name
            if target.exists():
                log(f"Staged file already exists: {target}")
            else:
                log(f"Downloading {item.get('episode_title')} as {final_name}")
                try:
                    download_episode(item, target)
                except Exception as exc:
                    gotify(
                        "Bluey YLE download failed",
                        (
                            f"Failed to download {item.get('episode_title')} "
                            f"({program_id}): {exc}"
                        ),
                        priority=5,
                    )
                    raise

            command_id = trigger_sonarr_import(api_key)
            handled[program_id] = {
                "status": "import_triggered",
                "season": season,
                "episode": episode_number,
                "file": str(target),
                "sonarr_command_id": command_id,
                "handled_at": utc_now(),
            }
            write_json(state_path, state)
            imported += 1
            gotify(
                "Bluey YLE import triggered",
                (
                    f"Downloaded {SERIES_TITLE} "
                    f"S{season:02d}E{episode_number:02d} "
                    f"{sonarr_episode['title']} and triggered Sonarr import."
                ),
                priority=2,
            )

        log(f"Done: imported={imported} suggested={suggested} skipped={skipped}")


    if __name__ == "__main__":
        try:
            main()
        except Exception as exc:
            gotify("Bluey YLE importer failed", str(exc), priority=5)
            raise
  '';
in {
  systemd.services.yle-bluey-sonarr-import = {
    description = "Download mapped YLE Bluey episodes and ask Sonarr to import them";
    after = ["network-online.target" "docker.service"];
    wants = ["network-online.target"];
    unitConfig.ConditionPathExists = config.age.secrets.yle-sonarr-import-env.path;
    path = [
      pkgs.yle-dl
      pkgs.ffmpeg
    ];
    environment = {
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    };
    serviceConfig = {
      Type = "oneshot";
      User = "apps";
      Group = "apps";
      StateDirectory = "yle-sonarr-import";
      EnvironmentFile = [
        config.age.secrets.hermes-env.path
        config.age.secrets.yle-sonarr-import-env.path
      ];
      ExecStart = "${importer}/bin/yle-bluey-sonarr-import";
    };
  };

  systemd.timers.yle-bluey-sonarr-import = {
    description = "Daily YLE Bluey Sonarr import";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* 06:30:00";
      Persistent = true;
      RandomizedDelaySec = "20m";
    };
  };
}
