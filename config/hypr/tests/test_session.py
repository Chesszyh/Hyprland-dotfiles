import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("session", Path(__file__).parents[1] / "scripts/session.py")
session = importlib.util.module_from_spec(spec)
spec.loader.exec_module(session)


class SessionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        patcher = patch.object(session, "SESSION_DIR", self.directory)
        patcher.start()
        self.addCleanup(patcher.stop)
        self.client = {"address": "0x1", "class": "kitty", "workspace": {"id": 2, "name": "2"}, "title": "private content"}
        self.target = self.directory / "last_session.json"
        self.target.write_text(json.dumps({"clients": [self.client]}))

    def test_query_failure_preserves_last_session(self):
        before = self.target.read_bytes()
        with patch.object(session, "query", side_effect=subprocess.CalledProcessError(1, "hyprctl")):
            with self.assertRaises(subprocess.CalledProcessError):
                session.save_session()
        self.assertEqual(before, self.target.read_bytes())

    def test_automatic_empty_snapshot_preserves_session(self):
        before = self.target.read_bytes()
        with patch.object(session, "query", return_value=[]):
            self.assertEqual(session.save_session(), 0)
        self.assertEqual(before, self.target.read_bytes())

    def test_manual_empty_snapshot_is_explicit(self):
        with patch.object(session, "query", side_effect=[[], {"id": 1, "name": "1"}]), patch.object(session, "notify"):
            session.save_session("manual")
        self.assertEqual(json.loads(self.target.read_text())["clients"], [])

    def test_snapshot_omits_window_titles(self):
        with patch.object(session, "query", side_effect=[[self.client], {"id": 2, "name": "2"}]):
            session.save_session()
        data = json.loads(self.target.read_text())
        self.assertEqual(data["clients"], [{"class": "kitty", "workspace": {"id": 2, "name": "2"}}])
        self.assertEqual(self.target.stat().st_mode & 0o777, 0o600)

    def test_repeated_restore_reuses_windows_without_launching(self):
        def query(name):
            return self.client if name == "activewindow" else [self.client]
        with patch.object(session, "query", side_effect=query), patch.object(session, "dispatch") as dispatch, patch.object(session, "notify"):
            for _ in range(2):
                self.assertEqual(session.restore_session(), {"existing": 1, "opened": 0, "skipped": 0})
        self.assertFalse(any("exec_cmd" in c.args[0] for c in dispatch.call_args_list))

    def test_flatpak_chat_launchers(self):
        self.assertEqual(session.command_for("QQ"), ["flatpak", "run", "com.qq.QQ"])
        self.assertEqual(session.command_for("wechat"), ["flatpak", "run", "com.tencent.WeChat"])

    def test_launch_failure_is_not_reported_as_restored(self):
        with patch.object(session, "query", side_effect=lambda name: {} if name == "activewindow" else []), \
             patch.object(session, "command_for", return_value=["kitty"]), \
             patch.object(session, "dispatch"), patch.object(session, "notify"), \
             patch.object(session.time, "monotonic", side_effect=[0, 9]):
            self.assertEqual(session.restore_session(), {"existing": 0, "opened": 0, "skipped": 1})

    def test_new_window_is_observed_before_counting_it(self):
        replies = [{}, [], [self.client], [self.client]]
        with patch.object(session, "query", side_effect=replies), \
             patch.object(session, "command_for", return_value=["kitty"]), \
             patch.object(session, "dispatch"), patch.object(session, "notify"):
            self.assertEqual(session.restore_session(), {"existing": 0, "opened": 1, "skipped": 0})


if __name__ == "__main__":
    unittest.main()
