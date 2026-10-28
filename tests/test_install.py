import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('installer', ROOT / 'tools/install.py')
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class InstallTests(unittest.TestCase):
    def test_preview_does_not_write_destination(self):
        with tempfile.TemporaryDirectory() as directory, contextlib.redirect_stdout(io.StringIO()):
            home = Path(directory) / 'new home'
            installer.install(home, installer.COMPONENTS)
            self.assertFalse(home.exists())

    def test_install_backs_up_existing_files_and_preserves_unrelated_services(self):
        with tempfile.TemporaryDirectory() as directory, contextlib.redirect_stdout(io.StringIO()):
            home = Path(directory) / 'new home'
            kitty = home / '.config/kitty'
            kitty.mkdir(parents=True)
            (kitty / 'local.txt').write_text('previous settings')
            units = home / '.config/systemd/user'
            units.mkdir(parents=True)
            (units / 'other.service').write_text('unrelated')
            (units / 'qs.service').write_text('old shell service')
            backup = installer.install(home, installer.COMPONENTS, apply=True)
            self.assertEqual((backup / 'kitty/local.txt').read_text(), 'previous settings')
            self.assertEqual((backup / 'systemd/user/qs.service').read_text(), 'old shell service')
            self.assertEqual((units / 'other.service').read_text(), 'unrelated')
            self.assertIn('Quickshell', (units / 'qs.service').read_text())
            state = home / '.local/state/dark-angel'
            self.assertEqual((state / 'current').read_text().strip(), 'dark')
            self.assertIn('primaryText', json.loads((state / 'qml_color.json').read_text()))
            self.assertTrue((home / '.config/waybar/config').is_file())
            self.assertTrue((home / '.config/waybar/style.css').is_file())
            self.assertTrue((units / 'hypridle-inhibit.service').is_file())
            self.assertTrue((home / '.config/kitty/scripts/kitty-session-save.sh').is_file())

    def test_installed_lua_entry_loads_without_private_state(self):
        with tempfile.TemporaryDirectory() as directory, contextlib.redirect_stdout(io.StringIO()):
            home = Path(directory)
            installer.install(home, installer.COMPONENTS, apply=True)
            harness = '''
local node = {}
setmetatable(node, { __index = function() return node end, __call = function() return node end })
hl = setmetatable({}, { __index = function() return node end })
local configured, monitor = false, false
hl.config = function(value) if value.general then configured = true end end
hl.monitor = function(value) monitor = value.output == "" end
dofile(...)
assert(configured and monitor)
'''
            result = subprocess.run(['lua', '-', str(home / '.config/hypr/hyprland.lua')], input=harness,
                                    env=dict(os.environ, HOME=str(home)), capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
