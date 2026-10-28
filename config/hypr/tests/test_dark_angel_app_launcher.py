import importlib.util
import io
import sys
import unittest
from pathlib import Path
from unittest import mock
from contextlib import redirect_stdout


MODULE_PATH = Path(__file__).resolve().parents[1] / "UserScripts" / "DarkAngelAppLauncher.py"
SPEC = importlib.util.spec_from_file_location("dark_angel_app_launcher", MODULE_PATH)
LAUNCHER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = LAUNCHER
assert SPEC.loader is not None
SPEC.loader.exec_module(LAUNCHER)


class DarkAngelAppLauncherTests(unittest.TestCase):
    def make_entry(self, **overrides):
        data = {
            "desktop_id": "demo.desktop",
            "path": Path.home() / ".local" / "share" / "applications" / "demo.desktop",
            "name": "Demo App",
            "exec_line": "demo-app --start",
            "icon": "demo-icon",
            "terminal": False,
            "hidden": False,
            "no_display": False,
            "type_name": "Application",
        }
        data.update(overrides)
        return LAUNCHER.DesktopEntry(**data)

    def test_display_markup_shows_source_without_exec_or_literal_newline(self):
        entry = self.make_entry()
        markup = LAUNCHER.display_markup(entry)

        self.assertIn("Demo App", markup)
        self.assertIn("demo.desktop @ ~/.local/share/applications", markup)
        self.assertNotIn("demo-app --start", markup)
        self.assertNotIn("\\n", markup)

    def test_build_rofi_command_restores_modes_and_custom_keys(self):
        command = LAUNCHER.build_rofi_command(MODULE_PATH)
        modes = command[command.index("-modes") + 1]

        self.assertEqual(command[command.index("-show") + 1], LAUNCHER.SCRIPT_MODE_NAME)
        self.assertIn(f"{LAUNCHER.SCRIPT_MODE_NAME}:{MODULE_PATH}", modes)
        self.assertIn("run", modes)
        self.assertIn("filebrowser", modes)
        self.assertIn("window", modes)
        self.assertEqual(command[command.index("-kb-custom-1") + 1], "Delete")
        self.assertEqual(command[command.index("-kb-custom-2") + 1], "Control+c")
        self.assertEqual(command[command.index("-kb-custom-3") + 1], "Control+e")

    def test_script_payload_enables_hotkeys_and_row_metadata(self):
        payload = LAUNCHER.script_payload([self.make_entry()], message="ready", keep_selection=True, new_selection=0)

        self.assertIn("\0use-hot-keys\x1ftrue\n", payload)
        self.assertIn("\0no-custom\x1ftrue\n", payload)
        self.assertIn("\0keep-selection\x1ftrue\n", payload)
        self.assertIn("\0new-selection\x1f0\n", payload)
        self.assertIn("\x1finfo\x1fdemo.desktop", payload)
        self.assertIn("\0display\x1f", payload)

    def test_initial_script_mode_payload_primes_keep_flags(self):
        entry = self.make_entry()
        output = io.StringIO()

        with mock.patch.dict(LAUNCHER.os.environ, {"ROFI_RETV": "0"}, clear=False):
            with mock.patch.object(LAUNCHER, "valid_entries", return_value=[entry]):
                with redirect_stdout(output):
                    result = LAUNCHER.script_mode(["launcher.py"])

        payload = output.getvalue()
        self.assertEqual(result, 0)
        self.assertIn("\0keep-selection\x1ftrue\n", payload)
        self.assertIn("\0keep-filter\x1ftrue\n", payload)

    def test_main_bypasses_argparse_for_rofi_callbacks(self):
        argv = ["launcher.py", "demo.desktop"]
        with mock.patch.dict(LAUNCHER.os.environ, {"ROFI_RETV": "11"}, clear=False):
            with mock.patch.object(LAUNCHER, "script_mode", return_value=0) as script_mode:
                result = LAUNCHER.main(argv)

        self.assertEqual(result, 0)
        script_mode.assert_called_once_with(argv)

    def test_build_rofi_command_uses_alt_arrows_for_mode_switching(self):
        command = LAUNCHER.build_rofi_command(MODULE_PATH)

        self.assertEqual(command[command.index("-kb-mode-next") + 1], "Alt+Right")
        self.assertEqual(command[command.index("-kb-mode-previous") + 1], "Alt+Left")
        self.assertEqual(command[command.index("-kb-row-left") + 1], "Left")
        self.assertEqual(command[command.index("-kb-row-right") + 1], "Right")

    def test_copy_action_keeps_current_selection_and_filter(self):
        entry = self.make_entry()
        output = io.StringIO()

        with mock.patch.dict(LAUNCHER.os.environ, {"ROFI_RETV": str(LAUNCHER.ROFI_CUSTOM_COPY), "ROFI_INFO": entry.desktop_id}, clear=False):
            with mock.patch.object(LAUNCHER, "valid_entries", return_value=[entry]):
                with mock.patch.object(LAUNCHER, "copy_to_clipboard", return_value=True):
                    with mock.patch.object(LAUNCHER, "notify"):
                        with redirect_stdout(output):
                            result = LAUNCHER.script_mode(["launcher.py", entry.desktop_id])

        payload = output.getvalue()
        self.assertEqual(result, 0)
        self.assertIn("\0keep-selection\x1ftrue\n", payload)
        self.assertIn("\0keep-filter\x1ftrue\n", payload)
        self.assertIn("\0new-selection\x1f0\n", payload)
        self.assertIn("Copied: ~/.local/share/applications/demo.desktop", payload)

    def test_delete_entry_removes_file(self):
        path = Path("tests/tmp-delete-entry.desktop")
        path.write_text("[Desktop Entry]\nType=Application\nName=Tmp\nExec=true\n", encoding="utf-8")
        entry = self.make_entry(path=path)

        ok, message = LAUNCHER.delete_entry(entry)

        self.assertTrue(ok)
        self.assertIn("Deleted tests/tmp-delete-entry.desktop", message)
        self.assertFalse(path.exists())


if __name__ == "__main__":
    unittest.main()
