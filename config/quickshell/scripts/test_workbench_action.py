#!/usr/bin/env python3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import workbench_action as wa


class WorkbenchActionTests(unittest.TestCase):
    def test_known_action_builds_command(self):
        self.assertEqual(wa.build_command("reload-hyprland", []), ["hyprctl", "-i", "0", "reload"])

    def test_unknown_action_is_rejected(self):
        with self.assertRaises(SystemExit):
            wa.build_command("unknown", [])

    def test_kill_pid_requires_confirm_flag(self):
        with self.assertRaises(SystemExit):
            wa.build_command("kill-pid", ["1234"])
        self.assertEqual(wa.build_command("kill-pid", ["1234", "--confirm"]), ["kill", "1234"])


if __name__ == "__main__":
    unittest.main()
