import argparse
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

BASE_STATE_DIR = Path("/var/lib/yle-sonarr-import")
HOST_DOWNLOAD_ROOT = Path("/mnt/illby/transient/sabnzbd-downloads/yle-dl")
SONARR_DOWNLOAD_ROOT = "/downloads/yle-dl"
SONARR_URL = "http://localhost:8989"
SONARR_CONFIG = Path("/mnt/illby/docker/data/sonarr/config.xml")
GOTIFY_URL = "https://gotify.cri.su/message"
OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
OPENROUTER_MODEL = os.environ.get(
    "OPENROUTER_MODEL",
    "anthropic/claude-haiku-4-5",
)

DEFAULT_SERIES = {
    "bluey-2018": {
        "enabled": True,
        "yle_url": "https://areena.yle.fi/1-66393054",
        "sonarr_series_id": 159,
        "language": "fi",
    }
}

DEFAULT_MAPPINGS = {
    "bluey-2018": {
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
}

SERIES_HEADER = """# One top-level key per Sonarr titleSlug / local series key.
# Required: yle_url.
# Optional: enabled (default true), sonarr_series_id (cached after lookup),
# language, prompt_hint.
"""

MAPPING_HEADER = """# Confirmed mappings. Only entries here can trigger downloads/imports.
# Keys are normalized YLE episode titles. Values are Sonarr season/episode.
"""

PENDING_HEADER = """# AI suggestions waiting for review.
# If a suggestion is correct, copy its season/episode into mapping.yaml.
"""

STATE_HEADER = """# Internal importer state. Usually do not edit by hand.
"""


def log(message):
    print(message, flush=True)


def read_yaml(path, default):
    if not path.exists():
        return default
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle)
    return default if data is None else data


def write_yaml(path, data, header=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as handle:
        if header:
            handle.write(header.rstrip())
            handle.write("\n")
        yaml.safe_dump(
            data,
            handle,
            allow_unicode=True,
            default_flow_style=False,
            sort_keys=False,
        )
    tmp.replace(path)
    path.chmod(0o664)


def migrate_json_file(yaml_path, default, header=None):
    json_path = yaml_path.with_suffix(".json")
    if yaml_path.exists() or not json_path.exists():
        return read_yaml(yaml_path, default)
    with json_path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)
    write_yaml(yaml_path, data, header=header)
    json_path.unlink()
    return data


def has_header(path):
    if not path.exists():
        return False
    with path.open("r", encoding="utf-8") as handle:
        first_line = handle.readline()
    return first_line.startswith("#")


def ensure_yaml_file(path, default, header=None):
    data = migrate_json_file(path, default, header=header)
    if not path.exists() or (header and not has_header(path)):
        write_yaml(path, data, header=header)
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


def fetch_sonarr_series(api_key):
    return sonarr_get("/api/v3/series", api_key)


def fetch_sonarr_episodes(api_key, series_id):
    episodes = sonarr_get(f"/api/v3/episode?seriesId={series_id}", api_key)
    by_number = {}
    for episode in episodes:
        episode_key = (episode["seasonNumber"], episode["episodeNumber"])
        by_number[episode_key] = episode
    return episodes, by_number


def fetch_yle_metadata(yle_url):
    result = subprocess.run(
        ["yle-dl", yle_url, "--showmetadata"],
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


def trigger_sonarr_import(api_key, sonarr_download_dir):
    command = sonarr_post(
        "/api/v3/command",
        api_key,
        {"name": "DownloadedEpisodesScan", "path": sonarr_download_dir},
    )
    return command.get("id") if isinstance(command, dict) else None


def series_title_slug(series):
    return series.get("titleSlug") or series.get("sortTitle")


def resolve_series_config(series_key, cfg, sonarr_series):
    if not isinstance(cfg, dict):
        raise ValueError(f"series '{series_key}' must be a mapping")
    if not cfg.get("yle_url"):
        raise ValueError(f"series '{series_key}' is missing required yle_url")

    result = dict(cfg)
    if result.get("enabled") is None:
        result["enabled"] = True

    by_slug = {series_title_slug(series): series for series in sonarr_series}
    by_id = {series.get("id"): series for series in sonarr_series}
    series = None
    if result.get("sonarr_series_id") is not None:
        series = by_id.get(int(result["sonarr_series_id"]))
    if series is None:
        series = by_slug.get(series_key)
    if series is None:
        raise ValueError(f"could not resolve Sonarr series '{series_key}'")

    result["sonarr_series_id"] = series["id"]
    result["sonarr_title"] = series.get("title") or series_key
    result["series_key"] = series_key
    result["state_dir"] = BASE_STATE_DIR / series_key
    result["host_download_dir"] = HOST_DOWNLOAD_ROOT / series_key
    result["sonarr_download_dir"] = f"{SONARR_DOWNLOAD_ROOT}/{series_key}"
    return result


def public_series_config(cfg):
    return {
        key: value
        for key, value in cfg.items()
        if key in ("enabled", "yle_url", "sonarr_series_id", "language", "prompt_hint")
    }


def ensure_series_file(path):
    return ensure_yaml_file(path, DEFAULT_SERIES, header=SERIES_HEADER)


def load_series_configs(path, api_key, selected=None):
    raw_configs = ensure_series_file(path)
    sonarr_series = fetch_sonarr_series(api_key)
    resolved = {}
    raw_changed = False

    for series_key, raw_cfg in raw_configs.items():
        if selected and series_key not in selected:
            continue
        try:
            cfg = resolve_series_config(series_key, raw_cfg, sonarr_series)
        except Exception as exc:
            log(f"Skipping {series_key}: {exc}")
            gotify("YLE Sonarr series config error", f"{series_key}: {exc}", 5)
            continue
        if not cfg.get("enabled", True):
            continue
        resolved[series_key] = cfg
        public_cfg = public_series_config(cfg)
        if raw_configs.get(series_key) != public_cfg:
            raw_configs[series_key] = public_cfg
            raw_changed = True

    if raw_changed:
        write_yaml(path, raw_configs, header=SERIES_HEADER)
    return resolved


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
        if episode.get("seasonNumber", 0) > 0
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


def ai_suggest(item, episodes, series):
    api_key = os.environ.get("OPENROUTER_API_KEY")
    if not api_key:
        return {
            "status": "ai_unavailable",
            "reason": "OPENROUTER_API_KEY is not configured",
        }

    candidates = sonarr_candidates(episodes)
    prompt = {
        "series": {
            "key": series["series_key"],
            "title": series["sonarr_title"],
            "language": series.get("language"),
            "prompt_hint": series.get("prompt_hint"),
        },
        "yle_episode": {
            "program_id": item.get("program_id"),
            "title": item.get("episode_title"),
            "description": item.get("description"),
            "publish_timestamp": item.get("publish_timestamp"),
            "duration_seconds": item.get("duration_seconds"),
        },
        "sonarr_candidates": candidates,
        "instructions": (
            "Map the localized YLE Areena episode to exactly one provided "
            "Sonarr candidate, or return no_match. The publish_timestamp is "
            "only YLE availability metadata, not the canonical episode air "
            "date. Prefer the title and description. For a match, return "
            "JSON only with keys status='match', season, episode, "
            "sonarr_title, confidence, reason. For no match, return JSON "
            "only with keys status='no_match', confidence, reason. Do not "
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
                        "You match localized YLE episode metadata to "
                        "canonical Sonarr episodes. Return strict JSON only."
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


def ensure_mapping_file(series_key, path):
    mapping = migrate_json_file(path, {}, header=MAPPING_HEADER)
    changed = False
    for title, value in DEFAULT_MAPPINGS.get(series_key, {}).items():
        if title not in mapping:
            mapping[title] = value
            changed = True
    if changed or not path.exists() or not has_header(path):
        write_yaml(path, mapping, header=MAPPING_HEADER)
    return mapping


def run_series(api_key, series):
    series_key = series["series_key"]
    state_dir = series["state_dir"]
    host_download_dir = series["host_download_dir"]
    host_download_dir.mkdir(parents=True, exist_ok=True)

    mapping_path = state_dir / "mapping.yaml"
    state_path = state_dir / "state.yaml"
    pending_path = state_dir / "pending-suggestions.yaml"

    mapping = ensure_mapping_file(series_key, mapping_path)
    state = ensure_yaml_file(
        state_path,
        {"handled_program_ids": {}},
        header=STATE_HEADER,
    )
    pending = ensure_yaml_file(pending_path, {}, header=PENDING_HEADER)
    handled = state.setdefault("handled_program_ids", {})

    episodes, episodes_by_number = fetch_sonarr_episodes(
        api_key,
        series["sonarr_series_id"],
    )
    candidates = sonarr_candidates(episodes)
    pending, pending_changed = normalize_pending_entries(pending, candidates)
    if pending_changed:
        write_yaml(pending_path, pending, header=PENDING_HEADER)
    metadata = fetch_yle_metadata(series["yle_url"])
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
                suggestion = ai_suggest(item, episodes, series)
                pending[program_id] = ordered_pending_entry({
                    "program_id": program_id,
                    "status": "needs_review",
                    "created_at": utc_now(),
                    "yle_title": item.get("episode_title"),
                    "yle_description": item.get("description"),
                    "publish_timestamp": item.get("publish_timestamp"),
                    "suggestion": suggestion,
                }, candidates)
                write_yaml(pending_path, pending, header=PENDING_HEADER)
                suggested += 1
                gotify(
                    "YLE import needs mapping",
                    (
                        f"New unmapped {series_key} episode: "
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
                "YLE import mapping error",
                (
                    f"{series_key}: {item.get('episode_title')} maps to "
                    f"missing S{season:02d}E{episode_number:02d} in Sonarr."
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
            write_yaml(state_path, state, header=STATE_HEADER)
            skipped += 1
            continue

        final_name = (
            f"{series['sonarr_title']} - S{season:02d}E{episode_number:02d} - "
            f"{safe_filename(sonarr_episode['title'])} WEB-DL-1080p.mkv"
        )
        target = host_download_dir / final_name
        if target.exists():
            log(f"{series_key}: staged file already exists: {target}")
        else:
            log(f"{series_key}: downloading {item.get('episode_title')} as {final_name}")
            try:
                download_episode(item, target)
            except Exception as exc:
                gotify(
                    "YLE download failed",
                    (
                        f"{series_key}: failed to download "
                        f"{item.get('episode_title')} ({program_id}): {exc}"
                    ),
                    priority=5,
                )
                raise

        command_id = trigger_sonarr_import(api_key, series["sonarr_download_dir"])
        handled[program_id] = {
            "status": "import_triggered",
            "season": season,
            "episode": episode_number,
            "file": str(target),
            "sonarr_command_id": command_id,
            "handled_at": utc_now(),
        }
        write_yaml(state_path, state, header=STATE_HEADER)
        imported += 1
        gotify(
            "YLE import triggered",
            (
                f"Downloaded {series['sonarr_title']} "
                f"S{season:02d}E{episode_number:02d} "
                f"{sonarr_episode['title']} and triggered Sonarr import."
            ),
            priority=2,
        )

    return {"imported": imported, "suggested": suggested, "skipped": skipped}


def run(args):
    BASE_STATE_DIR.mkdir(parents=True, exist_ok=True)
    api_key = sonarr_api_key()
    selected = set(args.series or [])
    series_configs = load_series_configs(
        BASE_STATE_DIR / "series.yaml",
        api_key,
        selected=selected,
    )
    if selected:
        missing = selected - set(series_configs)
        for series_key in sorted(missing):
            log(f"Requested series not runnable: {series_key}")

    totals = {"imported": 0, "suggested": 0, "skipped": 0, "failed": 0}
    for series_key, series in series_configs.items():
        try:
            result = run_series(api_key, series)
        except Exception as exc:
            totals["failed"] += 1
            gotify("YLE importer failed", f"{series_key}: {exc}", priority=5)
            log(f"{series_key}: failed: {exc}")
            continue
        for key in ("imported", "suggested", "skipped"):
            totals[key] += result[key]
        log(
            f"{series_key}: imported={result['imported']} "
            f"suggested={result['suggested']} skipped={result['skipped']}"
        )

    log(
        "Done: "
        f"imported={totals['imported']} suggested={totals['suggested']} "
        f"skipped={totals['skipped']} failed={totals['failed']}"
    )


def parse_args(argv=None):
    parser = argparse.ArgumentParser(description="Import YLE episodes into Sonarr")
    subparsers = parser.add_subparsers(dest="command")
    run_parser = subparsers.add_parser("run", help="run the importer")
    run_parser.add_argument(
        "--series",
        action="append",
        help="run only this series key; repeat for multiple series",
    )
    parser.set_defaults(command="run", series=None)
    return parser.parse_args(argv)


def main(argv=None):
    args = parse_args(argv)
    if args.command == "run":
        run(args)
    else:
        raise RuntimeError(f"Unknown command: {args.command}")


if __name__ == "__main__":
    main()
