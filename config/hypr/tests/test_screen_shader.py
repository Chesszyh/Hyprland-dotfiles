from pathlib import Path
import subprocess
import tempfile
import unittest


SETTINGS = Path(__file__).parents[1] / "configs/settings.lua"


class ScreenShaderStateTests(unittest.TestCase):
    def shader_path(self, root):
        harness = """
local root, settings = ...
hl = {
    config = function(value) shader = value.decoration.screen_shader end,
    device = function() end,
    gesture = function() end,
}
dofile(settings)({ home = root, colors = {} })
io.write(shader)
"""
        return subprocess.run(
            ["lua", "-", str(root), str(SETTINGS)],
            input=harness, capture_output=True, text=True, check=True,
        ).stdout

    def test_theme_defaults_and_persisted_manual_choice(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            state = root / ".local/state/dark-angel"
            state.mkdir(parents=True)
            for theme, manual, enabled in (
                ("dark", None, True), ("light", None, False),
                ("dark", "off", False), ("light", "on", True),
                ("dark", "on", True), ("light", "off", False),
            ):
                with self.subTest(theme=theme, manual=manual):
                    (state / "current").write_text(theme + "\n")
                    override = state / "screen-shader"
                    override.unlink(missing_ok=True)
                    if manual is not None:
                        override.write_text(manual + "\n")
                    expected = str(root / ".config/hypr/shaders/abyss_vignette.frag") if enabled else ""
                    self.assertEqual(self.shader_path(root), expected)
                    self.assertEqual(self.shader_path(root), expected)


if __name__ == "__main__":
    unittest.main()
