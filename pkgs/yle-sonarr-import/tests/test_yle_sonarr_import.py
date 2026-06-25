import json
import pathlib
import stat
import tempfile
import unittest
from unittest import mock

from yle_sonarr_import import cli as IMPORTER


class SuggestionValidationTest(unittest.TestCase):
    def setUp(self):
        self.candidates = [
            {
                "season": 2,
                "episode": 1,
                "title": "Dance Mode",
                "hasFile": False,
                "monitored": True,
                "airDate": "2020-03-17",
            },
            {
                "season": 2,
                "episode": 2,
                "title": "Hammerbarn",
                "hasFile": True,
                "monitored": True,
                "airDate": "2020-03-18",
            },
        ]

    def test_valid_match_is_normalized_to_ints(self):
        suggestion = {
            "status": "match",
            "season": "2",
            "episode": "1",
            "confidence": 0.93,
            "reason": "Description matches Dance Mode.",
        }

        result = IMPORTER.sanitize_ai_suggestion(suggestion, self.candidates)

        self.assertEqual(result["status"], "match")
        self.assertEqual(result["season"], 2)
        self.assertEqual(result["episode"], 1)
        self.assertEqual(result["sonarr_title"], "Dance Mode")
        self.assertEqual(result["sonarr_library_status"], "missing")
        self.assertFalse(result["sonarr_has_file"])
        self.assertTrue(result["sonarr_monitored"])
        self.assertEqual(result["sonarr_air_date"], "2020-03-17")

    def test_pending_entry_uses_review_friendly_order(self):
        entry = {
            "created_at": "2026-06-25T17:30:58Z",
            "suggestion": {
                "confidence": 0.92,
                "episode": 1,
                "reason": "Description matches Dance Mode.",
                "season": 2,
                "sonarr_title": "Dance Mode",
                "status": "match",
            },
            "yle_description": "Dance game description.",
            "status": "needs_review",
            "publish_timestamp": "2026-06-24T17:45:43+03:00",
            "program_id": "1-73049397",
            "yle_title": "Tuuri: Tanssikohtaus",
        }

        result = IMPORTER.ordered_pending_entry(entry, self.candidates)

        self.assertEqual(
            list(result.keys()),
            [
                "program_id",
                "status",
                "created_at",
                "yle_title",
                "yle_description",
                "publish_timestamp",
                "suggestion",
            ],
        )
        self.assertEqual(
            list(result["suggestion"].keys()),
            [
                "status",
                "season",
                "episode",
                "sonarr_title",
                "sonarr_library_status",
                "sonarr_has_file",
                "sonarr_monitored",
                "sonarr_air_date",
                "confidence",
                "reason",
            ],
        )

    def test_no_match_drops_null_episode_fields(self):
        suggestion = {
            "status": "no_match",
            "season": 2,
            "episode": 1,
            "sonarr_title": "Dance Mode",
            "confidence": 0,
            "reason": "Unclear.",
        }

        result = IMPORTER.sanitize_ai_suggestion(suggestion, self.candidates)

        self.assertEqual(result["status"], "no_match")
        self.assertNotIn("season", result)
        self.assertNotIn("episode", result)
        self.assertNotIn("sonarr_title", result)

    def test_match_to_missing_candidate_is_rejected(self):
        suggestion = {
            "status": "match",
            "season": 9,
            "episode": 99,
            "confidence": 0.8,
            "reason": "Invented candidate.",
        }

        result = IMPORTER.sanitize_ai_suggestion(suggestion, self.candidates)

        self.assertEqual(result["status"], "invalid_suggestion")
        self.assertIn("not a provided candidate", result["reason"])
        self.assertEqual(result["raw_suggestion"], suggestion)

    def test_sonarr_candidates_include_unmonitored_episodes(self):
        result = IMPORTER.sonarr_candidates([
            {
                "seasonNumber": 1,
                "episodeNumber": 1,
                "title": "Episode One",
                "hasFile": False,
                "monitored": False,
            }
        ])

        self.assertEqual(len(result), 1)
        self.assertFalse(result[0]["monitored"])


class StateFileTest(unittest.TestCase):
    def test_migrates_legacy_json_file_to_yaml(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            yaml_path = pathlib.Path(tmpdir) / "mapping.yaml"
            json_path = pathlib.Path(tmpdir) / "mapping.json"
            expected = {"tuuri: tanssikohtaus": {"season": 2, "episode": 1}}
            json_path.write_text(
                json.dumps(expected, ensure_ascii=False),
                encoding="utf-8",
            )

            result = IMPORTER.migrate_json_file(yaml_path, {})

            self.assertEqual(result, expected)
            self.assertTrue(yaml_path.exists())
            self.assertFalse(json_path.exists())
            self.assertEqual(IMPORTER.read_yaml(yaml_path, {}), expected)
            mode = stat.S_IMODE(yaml_path.stat().st_mode)
            self.assertEqual(mode, 0o664)

    def test_empty_yaml_file_uses_default(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            yaml_path = pathlib.Path(tmpdir) / "pending-suggestions.yaml"
            yaml_path.write_text("", encoding="utf-8")

            result = IMPORTER.read_yaml(yaml_path, {})

            self.assertEqual(result, {})

    def test_ensure_yaml_file_adds_missing_header(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            yaml_path = pathlib.Path(tmpdir) / "state.yaml"
            IMPORTER.write_yaml(yaml_path, {"handled_program_ids": {}})

            IMPORTER.ensure_yaml_file(
                yaml_path,
                {"handled_program_ids": {}},
                header=IMPORTER.STATE_HEADER,
            )

            contents = yaml_path.read_text(encoding="utf-8")
            self.assertTrue(contents.startswith("# Internal importer state"))

    def test_parse_args_defaults_to_run(self):
        result = IMPORTER.parse_args([])

        self.assertEqual(result.command, "run")
        self.assertIsNone(result.series)

    def test_resolves_minimal_series_config_from_slug(self):
        cfg = {"enabled": True, "yle_url": "https://arenan.yle.fi/1-50504909"}
        sonarr_series = [{"id": 321, "titleSlug": "alfie-atkins-2012", "title": "Alfie Atkins (2012)"}]

        result = IMPORTER.resolve_series_config(
            "alfie-atkins-2012",
            cfg,
            sonarr_series,
        )

        self.assertEqual(result["sonarr_series_id"], 321)
        self.assertEqual(result["sonarr_title"], "Alfie Atkins (2012)")
        self.assertEqual(
            result["state_dir"],
            IMPORTER.BASE_STATE_DIR / "alfie-atkins-2012",
        )
        self.assertEqual(
            result["host_download_dir"],
            IMPORTER.HOST_DOWNLOAD_ROOT / "alfie-atkins-2012",
        )
        self.assertEqual(
            result["sonarr_download_dir"],
            "/downloads/yle-dl/alfie-atkins-2012",
        )

    def test_load_series_configs_caches_resolved_id_only(self):
        sonarr_series = [{"id": 321, "titleSlug": "alfie-atkins-2012", "title": "Alfie Atkins (2012)"}]
        with tempfile.TemporaryDirectory() as tmpdir:
            series_path = pathlib.Path(tmpdir) / "series.yaml"
            IMPORTER.write_yaml(
                series_path,
                {
                    "alfie-atkins-2012": {
                        "enabled": True,
                        "yle_url": "https://arenan.yle.fi/1-50504909",
                    }
                },
                header=IMPORTER.SERIES_HEADER,
            )

            with mock.patch.object(IMPORTER, "fetch_sonarr_series", return_value=sonarr_series):
                result = IMPORTER.load_series_configs(series_path, "api-key")

            self.assertEqual(result["alfie-atkins-2012"]["sonarr_series_id"], 321)
            written = IMPORTER.read_yaml(series_path, {})
            self.assertEqual(
                written,
                {
                    "alfie-atkins-2012": {
                        "enabled": True,
                        "yle_url": "https://arenan.yle.fi/1-50504909",
                        "sonarr_series_id": 321,
                    }
                },
            )
            contents = series_path.read_text(encoding="utf-8")
            self.assertIn("# One top-level key", contents)
            self.assertNotIn("host_download_dir", contents)
            self.assertNotIn("sonarr_slug", contents)


if __name__ == "__main__":
    unittest.main()
