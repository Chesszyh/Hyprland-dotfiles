import importlib.util
import sys
from pathlib import Path
from unittest import mock


SCRIPTS = Path(__file__).parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))
SCRIPT = SCRIPTS / "X11CliphistWatch.py"
SPEC = importlib.util.spec_from_file_location("x11_cliphist_watch", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


def test_image_offer_never_enters_text_bridge():
    def selection(command, **kwargs):
        if command[-1] == "TARGETS":
            return mock.Mock(returncode=0, stdout=b"TARGETS\nimage/png\n")
        return mock.Mock(returncode=0, stdout=b"\x89PNG\r\n\x1a\nimage payload")

    with mock.patch.object(MODULE.subprocess, "run", side_effect=selection):
        assert MODULE.read_x11_clipboard() == b""


def test_rich_offer_is_not_flattened_to_plain_text():
    for formats in (b"image/png\nUTF8_STRING\n", b"text/html\nUTF8_STRING\n", b"text/uri-list\nUTF8_STRING\n"):
        with mock.patch.object(MODULE.subprocess, "run", return_value=mock.Mock(returncode=0, stdout=formats)):
            assert MODULE.read_x11_clipboard() == b""


def test_explicit_utf8_text_is_read_without_default_conversion():
    data = "中文 clipboard text".encode()
    def selection(command, **kwargs):
        if command[-1] == "TARGETS":
            return mock.Mock(returncode=0, stdout=b"TARGETS\nTIMESTAMP\nTK_APPLICATION\nTK_WINDOW\nUTF8_STRING\nSTRING\n")
        assert command[-2:] == ["-target", "UTF8_STRING"]
        return mock.Mock(returncode=0, stdout=data)
    with mock.patch.object(MODULE.subprocess, "run", side_effect=selection):
        assert MODULE.read_x11_clipboard() == data


def test_unreadable_targets_do_not_trigger_default_read():
    with mock.patch.object(MODULE.subprocess, "run", return_value=mock.Mock(returncode=1, stdout=b"")) as run:
        assert MODULE.read_x11_clipboard() == b""
        assert run.call_count == 1


def test_publishes_x11_text_to_wayland():
    process = mock.Mock()

    with mock.patch.object(MODULE.subprocess, "Popen", return_value=process) as popen:
        assert MODULE.publish_wayland_clipboard(b"copied from XWayland") is process

    popen.assert_called_once_with(
        ["/usr/bin/wl-copy", "--foreground", "--type", "text/plain"],
        stdin=MODULE.subprocess.PIPE,
        stderr=MODULE.subprocess.DEVNULL,
    )
    process.stdin.write.assert_called_once_with(b"copied from XWayland")
    process.stdin.close.assert_called_once_with()


def test_publish_failure_does_not_crash_watcher():
    with mock.patch.object(
        MODULE.subprocess,
        "Popen",
        side_effect=OSError("wl-copy failed"),
    ):
        assert MODULE.publish_wayland_clipboard(b"copied from XWayland") is None


def test_retries_until_wayland_owner_stays_alive():
    exited = mock.Mock()
    exited.poll.return_value = 1
    stable = mock.Mock()
    stable.poll.return_value = None

    with (
        mock.patch.object(
            MODULE,
            "publish_wayland_clipboard",
            side_effect=[exited, stable],
        ) as publish,
        mock.patch.object(MODULE.time, "sleep") as sleep,
    ):
        owner = MODULE.stabilize_wayland_clipboard(
            b"copied from XWayland",
            settle_time=0.01,
        )

    assert owner is stable
    assert publish.call_count == 2
    assert sleep.call_count == 2
