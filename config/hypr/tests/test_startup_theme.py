from pathlib import Path
import subprocess
import unittest


class StartupThemeTests(unittest.TestCase):
    def test_startup_does_not_replace_theme_with_random_borders(self):
        startup = Path(__file__).parents[1] / "configs/startup.lua"
        harness = """
local startup = ...
local commands = {}
local start
hl = {
    on = function(event, callback) if event == "hyprland.start" then start = callback end end,
    exec_cmd = function(command) table.insert(commands, command) end,
}
dofile(startup)({home="/home/test", user_scripts="/home/test/UserScripts", scripts="/home/test/scripts"})
start()
for _, command in ipairs(commands) do print(command) end
"""
        result = subprocess.run(["lua", "-", str(startup)], input=harness,
                                capture_output=True, text=True, check=True)
        self.assertNotIn("RainbowBorders.sh", result.stdout)
