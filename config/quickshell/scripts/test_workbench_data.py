#!/usr/bin/env python3
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))

import workbench_data as wd


class WorkbenchDataTests(unittest.TestCase):
    def test_git_branch_parser_handles_ahead_behind_and_dirty(self):
        status = "## main...origin/main [ahead 2, behind 1]\n M README.md\n?? new.py\n"
        parsed = wd.parse_git_status(status)
        self.assertEqual(parsed["branch"], "main")
        self.assertEqual(parsed["upstream"], "origin/main")
        self.assertEqual(parsed["ahead"], 2)
        self.assertEqual(parsed["behind"], 1)
        self.assertEqual(parsed["dirty_count"], 2)

    def test_tailscale_parser_groups_online_and_offline(self):
        payload = {
            "Self": {"HostName": "fedora", "TailscaleIPs": ["100.64.0.1"], "OS": "linux", "Online": True},
            "Peer": {
                "abc": {"HostName": "nas", "TailscaleIPs": ["100.64.0.2"], "OS": "linux", "Online": True},
                "def": {"HostName": "phone", "TailscaleIPs": ["100.64.0.3"], "OS": "android", "Online": False, "LastSeen": "2026-05-28T10:00:00Z"},
            },
            "ExitNodeStatus": {"ID": "abc", "Online": True},
        }
        parsed = wd.parse_tailscale_status(payload)
        self.assertEqual(parsed["summary"]["online"], 2)
        self.assertEqual(parsed["summary"]["offline"], 1)
        self.assertEqual(parsed["summary"]["exit_node_id"], "abc")
        self.assertEqual(parsed["peers"][0]["host"], "fedora")
        self.assertEqual(parsed["peers"][1]["host"], "nas")

    def test_witr_parser_extracts_process_fields_from_common_json_shape(self):
        payload = {"results": [{"port": "3000", "process": {"pid": 123, "name": "node", "cmdline": "node server.js", "cwd": "/tmp/app"}}]}
        parsed = wd.parse_witr_result(payload, "3000")
        self.assertEqual(parsed["port"], "3000")
        self.assertEqual(parsed["process"]["pid"], 123)
        self.assertEqual(parsed["process"]["name"], "node")

    def test_envelope_is_stable_json_shape(self):
        envelope = wd.envelope("repos", [{"name": "demo"}], warnings=["stale"])
        encoded = json.loads(json.dumps(envelope))
        self.assertTrue(encoded["ok"])
        self.assertEqual(encoded["topic"], "repos")
        self.assertEqual(encoded["items"][0]["name"], "demo")
        self.assertEqual(encoded["warnings"], ["stale"])

    def test_parser_accepts_positional_search_query(self):
        args = wd.build_parser().parse_args(["search", "tailscale"])
        self.assertEqual(args.topic, "search")
        self.assertEqual(args.search_query, "tailscale")

    def test_find_git_repos_prunes_heavy_directories(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            good = root / "good"
            skipped = root / "node_modules" / "bad"
            (good / ".git").mkdir(parents=True)
            (skipped / ".git").mkdir(parents=True)

            warnings = []
            repos = wd.find_git_repos([str(root)], warnings)

        self.assertEqual(repos, [good.resolve()])

    def test_collect_repos_skips_failed_git_status(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            valid = root / "valid"
            invalid = root / "invalid"
            (valid / ".git").mkdir(parents=True)
            (invalid / ".git").mkdir(parents=True)

            def fake_status(command, warnings, label, *, timeout=8):
                del command, timeout
                if label.endswith(str(invalid)):
                    warnings.append(f"{label}: failed")
                    return None
                return "## main\n"

            with mock.patch.object(wd, "run_text_command", side_effect=fake_status):
                result = wd.collect_repos({"repo_roots": [str(root)]})

        self.assertEqual([item["name"] for item in result["items"]], ["valid"])
        self.assertTrue(any("invalid" in warning for warning in result["warnings"]))

    def test_search_does_not_call_live_collectors(self):
        with (
            mock.patch.object(wd, "collect_repos", side_effect=AssertionError("live repos")),
            mock.patch.object(wd, "collect_network", side_effect=AssertionError("live network")),
            mock.patch.object(wd, "collect_runtime", side_effect=AssertionError("live runtime")),
            mock.patch.object(wd, "collect_agents", side_effect=AssertionError("live agents")),
        ):
            result = wd.collect_search({"repo_roots": [], "ssh_hosts": []}, query="quickshell")

        self.assertEqual(result["topic"], "search")
        self.assertTrue(result["ok"])

    def test_visual_topic_reports_animation_tools_without_running_them(self):
        with mock.patch.object(wd.shutil, "which", side_effect=lambda command: f"/usr/bin/{command}" if command == "cava" else None):
            args = wd.build_parser().parse_args(["visual"])
            result = wd.collect_topic("visual", {}, args)

        self.assertTrue(result["ok"])
        self.assertEqual(result["topic"], "visual")
        self.assertEqual(result["summary"]["available"], 1)
        self.assertEqual([item["name"] for item in result["items"]], ["cava", "pipes.sh"])
        self.assertTrue(result["items"][0]["available"])
        self.assertFalse(result["items"][1]["available"])


if __name__ == "__main__":
    unittest.main()
