import json
import os
import re
import subprocess
import time
import unicodedata
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

import yaml

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


def read_yaml(path, default):
    if not path.exists():
        return default
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    return default if data is None else data


def write_yaml(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as handle:
        yaml.safe_dump(
            data,
            handle,
            allow_unicode=True,
            default_flow_style=False,
            sort_keys=False,
        )
    tmp.replace(path)
    path.chmod(0o664)


def migrate_json_file(yaml_path, default):
    json_path = yaml_path.with_suffix(".json")
    if yaml_path.exists() or not json_path.exists():
        return read_yaml(yaml_path, default)
    with json_path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    write_yaml(yaml_path, data)
    json_path.unlink()
    return data


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


def sonarr_candidates(episodes):
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
    return candidates


def candidate_by_number(candidates):
    return {
        (candidate["season"], candidate["episode"]): candidate
        for candidate in candidates
    }


def ordered_suggestion(suggestion, candidates):
    if not isinstance(suggestion, dict):
        return suggestion

    status = suggestion.get("status")
    ordered = {"status": status} if status is not None else {}
    if status == "match":
        season = suggestion.get("season")
        episode = suggestion.get("episode")
        try:
            candidate = candidate_by_number(candidates).get(
                (int(season), int(episode))
            )
        except (TypeError, ValueError):
            candidate = None
        has_file = candidate.get("hasFile") if candidate else None

        ordered.update(
            {
                "season": season,
                "episode": episode,
                "sonarr_title": suggestion.get("sonarr_title"),
                "sonarr_library_status": (
                    "present" if has_file else "missing"
                    if has_file is not None else None
                ),
                "sonarr_has_file": has_file,
                "sonarr_monitored": (
                    candidate.get("monitored") if candidate else None
                ),
                "sonarr_air_date": (
                    candidate.get("airDate") if candidate else None
                ),
            }
        )

    for key in ("confidence", "reason", "raw_suggestion", "raw_response"):
        if key in suggestion:
            ordered[key] = suggestion[key]
    for key, value in suggestion.items():
        if key in ordered or key in ("hasFile", "monitored", "airDate"):
            continue
        ordered[key] = value
    return {key: value for key, value in ordered.items() if value is not None}


def ordered_pending_entry(entry, candidates):
    return {
        key: value
        for key, value in {
            "program_id": entry.get("program_id"),
            "status": entry.get("status"),
            "created_at": entry.get("created_at"),
            "yle_title": entry.get("yle_title"),
            "yle_description": entry.get("yle_description"),
            "publish_timestamp": entry.get("publish_timestamp"),
            "suggestion": ordered_suggestion(
                entry.get("suggestion", {}), candidates
            ),
        }.items()
        if value is not None
    }


def normalize_pending_entries(pending, candidates):
    normalized = {
        program_id: ordered_pending_entry(entry, candidates)
        for program_id, entry in pending.items()
    }
    return normalized, normalized != pending


def sanitize_ai_suggestion(suggestion, candidates):
    if not isinstance(suggestion, dict):
        return {
            "status": "invalid_suggestion",
            "reason": "AI response was not a JSON object",
            "raw_suggestion": suggestion,
        }

    status = suggestion.get("status")
    if status != "match":
        sanitized = dict(suggestion)
        sanitized["status"] = status or "no_match"
        for key in ("season", "episode", "sonarr_title"):
            sanitized.pop(key, None)
        return sanitized

    try:
        season = int(suggestion["season"])
        episode = int(suggestion["episode"])
    except (KeyError, TypeError, ValueError):
        return {
            "status": "invalid_suggestion",
            "reason": (
                "match response did not include integer season and episode"
            ),
            "raw_suggestion": suggestion,
        }

    candidate = candidate_by_number(candidates).get((season, episode))
    if not candidate:
        return {
            "status": "invalid_suggestion",
            "reason": (
                f"S{season:02d}E{episode:02d} is not a provided candidate"
            ),
            "raw_suggestion": suggestion,
        }

    sanitized = dict(suggestion)
    sanitized["season"] = season
    sanitized["episode"] = episode
    sanitized.setdefault("sonarr_title", candidate["title"])
    return ordered_suggestion(sanitized, candidates)


def ai_suggest(item, episodes):
    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        return {
            "status": "ai_unavailable",
            "reason": "OPENROUTER_API_KEY is not configured",
        }

    candidates = sonarr_candidates(episodes)
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
            "Map the Finnish-localized YLE Areena Bluey episode to exactly "
            "one provided Sonarr candidate, or return no_match. The "
            "publish_timestamp is only YLE availability metadata, not the "
            "canonical episode air date. Prefer the title and description. "
            "For a match, return JSON only with keys status='match', season, "
            "episode, sonarr_title, confidence, reason. For no match, return "
            "JSON only with keys status='no_match', confidence, reason. Do "
            "not invent candidates. Use no_match when uncertain."
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
                        "You match localized Finnish Bluey episode metadata "
                        "to canonical Sonarr episodes. Return strict JSON "
                        "only."
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
        return {"status": "parse_error", "raw_response": content}
    return sanitize_ai_suggestion(parsed, candidates)


def ensure_mapping_file(path):
    mapping = migrate_json_file(path, {})
    changed = False
    for title, value in DEFAULT_MAPPING.items():
        if title not in mapping:
            mapping[title] = value
            changed = True
    if changed or not path.exists():
        write_yaml(path, mapping)
    return mapping


def main():
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    HOST_DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)

    mapping_path = STATE_DIR / "mapping.yaml"
    state_path = STATE_DIR / "state.yaml"
    pending_path = STATE_DIR / "pending-suggestions.yaml"

    mapping = ensure_mapping_file(mapping_path)
    state = migrate_json_file(state_path, {"handled_program_ids": {}})
    pending = migrate_json_file(pending_path, {})
    handled = state.setdefault("handled_program_ids", {})

    api_key = sonarr_api_key()
    episodes, episodes_by_number = fetch_sonarr_episodes(api_key)
    candidates = sonarr_candidates(episodes)
    pending, pending_changed = normalize_pending_entries(pending, candidates)
    if pending_changed:
        write_yaml(pending_path, pending)
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
                pending[program_id] = ordered_pending_entry({
                    "program_id": program_id,
                    "status": "needs_review",
                    "created_at": utc_now(),
                    "yle_title": item.get("episode_title"),
                    "yle_description": item.get("description"),
                    "publish_timestamp": item.get("publish_timestamp"),
                    "suggestion": suggestion,
                }, candidates)
                write_yaml(pending_path, pending)
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
            write_yaml(state_path, state)
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
        write_yaml(state_path, state)
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
