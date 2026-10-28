import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch
from urllib.error import URLError
from urllib.parse import parse_qs, urlparse


spec = importlib.util.spec_from_file_location("weather", Path(__file__).parents[1] / "UserScripts/Weather.py")
weather = importlib.util.module_from_spec(spec)
spec.loader.exec_module(weather)

SAMPLE = {
    "current": {
        "time": "2026-10-27T22:30", "temperature_2m": 13.8,
        "relative_humidity_2m": 72, "apparent_temperature": 12.1,
        "is_day": 0, "weather_code": 0, "wind_speed_10m": 9.5,
    },
    "daily": {"temperature_2m_max": [20.9], "temperature_2m_min": [13.2]},
}


class WeatherTests(unittest.TestCase):
    def test_request_targets_shanghai_jiading_with_explicit_units(self):
        query = parse_qs(urlparse(weather.forecast_url()).query)
        self.assertEqual(query["latitude"], ["31.38575"])
        self.assertEqual(query["longitude"], ["121.24465"])
        self.assertEqual(query["timezone"], ["Asia/Shanghai"])
        self.assertEqual(query["temperature_unit"], ["celsius"])
        self.assertEqual(query["wind_speed_unit"], ["kmh"])

    def test_night_conditions_include_real_values_and_timestamp(self):
        output, summary = weather.render_weather(SAMPLE)
        self.assertEqual(output["text"], "󰖔  13.8°C")
        self.assertEqual(output["class"], "clearNight")
        for value in ("上海·嘉定", "12.1°C", "13.2°C", "20.9°C", "72%", "9.5 km/h", "2026-10-27 22:30"):
            self.assertIn(value, output["tooltip"])
        self.assertIn("上海·嘉定", summary)

    def test_fetch_bypasses_dead_desktop_proxy_and_has_timeout(self):
        opener = MagicMock()
        opener.open.return_value.__enter__.return_value = io.StringIO(json.dumps(SAMPLE))
        with patch.object(weather, "build_opener", return_value=opener) as build:
            self.assertEqual(weather.fetch_weather(), SAMPLE)
        self.assertEqual(build.call_args.args[0].proxies, {})
        opener.open.assert_called_once_with(weather.forecast_url(), timeout=10)

    def run_main(self, fetch, cache=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            if cache is not None:
                path = root / "hypr/weather-jiading.json"
                path.parent.mkdir()
                path.write_text(json.dumps(cache))
            stdout, stderr = io.StringIO(), io.StringIO()
            with patch.dict(os.environ, {"XDG_CACHE_HOME": directory}), patch.object(weather, "fetch_weather", fetch), contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
                self.assertEqual(weather.main(), 0)
            output = json.loads(stdout.getvalue())
            summary = (root / ".weather_cache").read_text()
            cached = json.loads((root / "hypr/weather-jiading.json").read_text()) if (root / "hypr/weather-jiading.json").exists() else None
            return output, summary, cached

    def test_success_updates_waybar_and_lockscreen_cache(self):
        output, summary, cached = self.run_main(MagicMock(return_value=SAMPLE))
        self.assertEqual(cached, SAMPLE)
        self.assertIn("13.8°C", summary)
        self.assertEqual(output["class"], "clearNight")

    def test_network_failure_labels_cached_data_as_stale(self):
        output, summary, cached = self.run_main(MagicMock(side_effect=URLError("offline")), SAMPLE)
        self.assertEqual(output["class"], "stale")
        self.assertIn("显示上次数据", output["tooltip"])
        self.assertIn("2026-10-27 22:30", summary)
        self.assertEqual(cached, SAMPLE)

    def test_network_failure_without_cache_is_explicit(self):
        output, summary, _ = self.run_main(MagicMock(side_effect=URLError("offline")))
        self.assertEqual(output["class"], "error")
        self.assertNotIn("°C", output["text"])
        self.assertIn("上海·嘉定", summary)

    def test_missing_temperature_is_not_shown_as_valid_weather(self):
        data = json.loads(json.dumps(SAMPLE))
        data["current"]["temperature_2m"] = None
        output, _, cached = self.run_main(MagicMock(return_value=data))
        self.assertEqual(output["class"], "error")
        self.assertIsNone(cached)
