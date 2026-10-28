#!/usr/bin/env python3
# Original Waybar integration: JaKooLit and Surendrajat.
# https://gist.github.com/Surendrajat/ff3876fd2166dd86fb71180f4e9342d7

import json
import os
from pathlib import Path
import sys
from urllib.error import URLError
from urllib.parse import urlencode
from urllib.request import ProxyHandler, build_opener


LOCATION = "上海·嘉定"
# Open-Meteo geocoding ID 1806508: Jiading, Shanghai, China.
LATITUDE, LONGITUDE = 31.38575, 121.24465
CONDITIONS = {
    0: "晴", 1: "大部晴朗", 2: "少云", 3: "多云", 45: "雾", 48: "雾凇",
    51: "小毛毛雨", 53: "毛毛雨", 55: "强毛毛雨", 56: "冻毛毛雨", 57: "强冻毛毛雨",
    61: "小雨", 63: "中雨", 65: "大雨", 66: "冻雨", 67: "强冻雨",
    71: "小雪", 73: "中雪", 75: "大雪", 77: "冰粒",
    80: "小阵雨", 81: "阵雨", 82: "强阵雨", 85: "阵雪", 86: "强阵雪",
    95: "雷暴", 96: "雷暴伴冰雹", 99: "强雷暴伴冰雹",
}


def forecast_url():
    return "https://api.open-meteo.com/v1/forecast?" + urlencode({
        "latitude": LATITUDE,
        "longitude": LONGITUDE,
        "current": "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m",
        "daily": "temperature_2m_max,temperature_2m_min",
        "timezone": "Asia/Shanghai",
        "forecast_days": 1,
        "temperature_unit": "celsius",
        "wind_speed_unit": "kmh",
    })


def fetch_weather():
    # The desktop may start before its local proxy is listening.
    opener = build_opener(ProxyHandler({}))
    with opener.open(forecast_url(), timeout=10) as response:
        return json.load(response)


def weather_icon(code, is_day):
    if code >= 95:
        return "", "severe"
    if code in (71, 73, 75, 77, 85, 86):
        return ("", "snowyIcyDay") if is_day else ("", "snowyIcyNight")
    if code in (51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82):
        return ("", "rainyDay") if is_day else ("", "rainyNight")
    if code in (2, 3, 45, 48):
        return ("", "cloudyFoggyDay") if is_day else ("", "cloudyFoggyNight")
    return ("󰖙", "sunnyDay") if is_day else ("󰖔", "clearNight")


def render_weather(data, *, stale=False):
    current, daily = data["current"], data["daily"]
    temp = f'{float(current["temperature_2m"]):g}°C'
    feels = f'{float(current["apparent_temperature"]):g}°C'
    low = f'{float(daily["temperature_2m_min"][0]):g}°C'
    high = f'{float(daily["temperature_2m_max"][0]):g}°C'
    humidity = f'{float(current["relative_humidity_2m"]):g}%'
    wind = f'{float(current["wind_speed_10m"]):g} km/h'
    code = int(current["weather_code"])
    condition = CONDITIONS.get(code, f"天气代码 {code}")
    icon, css_class = weather_icon(code, bool(current["is_day"]))
    updated = current["time"].replace("T", " ")
    tooltip = (
        f'<b>{LOCATION}</b>\n<span size="xx-large">{temp}</span>\n'
        f'{icon} <b>{condition}</b>\n体感 {feels}\n\n'
        f' {low}     {high}\n {wind}     {humidity}\n\n'
        f'<small>Open-Meteo · {updated}（北京时间）</small>'
    )
    summary = f'{LOCATION} · {condition}\n {temp}（体感 {feels}）\n {wind}   {humidity}\n{updated}\n'
    if stale:
        tooltip += "\n本次更新失败，显示上次数据"
        summary += "本次更新失败，显示上次数据\n"
    return {
        "text": f"{icon}  {temp}",
        "alt": f"{LOCATION} · {condition}",
        "tooltip": tooltip,
        "class": "stale" if stale else css_class,
    }, summary


def main():
    cache_dir = Path(os.environ.get("XDG_CACHE_HOME", str(Path.home() / ".cache")))
    cache = cache_dir / "hypr" / "weather-jiading.json"
    fresh = False
    try:
        data = fetch_weather()
        output, summary = render_weather(data)
        fresh = True
    except (URLError, TimeoutError, OSError, ValueError, KeyError, TypeError, IndexError) as error:
        print(f"Weather update failed: {error}", file=sys.stderr)
        try:
            data = json.loads(cache.read_text())
            output, summary = render_weather(data, stale=True)
        except (OSError, ValueError, KeyError, TypeError, IndexError):
            output = {"text": " --", "alt": LOCATION, "tooltip": f"{LOCATION}\n天气暂不可用", "class": "error"}
            summary = f"{LOCATION}\n天气暂不可用\n"
    try:
        cache_dir.mkdir(parents=True, exist_ok=True)
        if fresh:
            cache.parent.mkdir(parents=True, exist_ok=True)
            cache.write_text(json.dumps(data, ensure_ascii=False) + "\n")
        (cache_dir / ".weather_cache").write_text(summary)
    except OSError as error:
        print(f"Weather cache write failed: {error}", file=sys.stderr)
    print(json.dumps(output, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
