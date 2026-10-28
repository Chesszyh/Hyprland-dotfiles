import importlib.util
import os
import time
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "CliphistStore.py"
SPEC = importlib.util.spec_from_file_location("cliphist_store", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


def test_returns_buffered_data_when_writer_keeps_pipe_open():
    read_fd, write_fd = os.pipe()
    try:
        os.write(write_fd, b"chrome clipboard text")

        started_at = time.monotonic()
        data = MODULE.read_clipboard_data(
            read_fd,
            start_timeout=0.1,
            idle_timeout=0.02,
            absolute_timeout=0.2,
        )

        assert data == b"chrome clipboard text"
        assert time.monotonic() - started_at < 0.15
    finally:
        os.close(read_fd)
        os.close(write_fd)


def test_returns_immediately_after_normal_eof():
    read_fd, write_fd = os.pipe()
    try:
        os.write(write_fd, b"normal clipboard text")
        os.close(write_fd)
        write_fd = -1

        started_at = time.monotonic()
        data = MODULE.read_clipboard_data(read_fd)

        assert data == b"normal clipboard text"
        assert time.monotonic() - started_at < 0.1
    finally:
        os.close(read_fd)
        if write_fd >= 0:
            os.close(write_fd)
