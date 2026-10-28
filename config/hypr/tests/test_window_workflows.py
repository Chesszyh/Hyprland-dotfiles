import importlib.util
import os
from pathlib import Path
import unittest

os.environ.setdefault("XDG_RUNTIME_DIR", "/tmp")
spec = importlib.util.spec_from_file_location("dropdown", Path(__file__).parents[1] / "scripts/dropterminal.py")
dropdown = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dropdown)


class MonitorGeometryTests(unittest.TestCase):
    def test_scaled_external_monitor(self):
        self.assertEqual(dropdown.geometry({"x": 0, "y": 0, "width": 3840, "height": 2160, "scale": 1.2}),
                         (800, 90, 1600, 900))

    def test_offset_internal_monitor(self):
        self.assertEqual(dropdown.geometry({"x": 3200, "y": 0, "width": 2560, "height": 1600, "scale": 1}),
                         (3840, 80, 1280, 800))


if __name__ == "__main__":
    unittest.main()
