#!/usr/bin/python3

import os
import select
import subprocess
import sys
import time


def read_clipboard_data(
    fd: int,
    *,
    start_timeout: float = 2.0,
    idle_timeout: float = 0.25,
    absolute_timeout: float = 15.0,
) -> bytes:
    started_at = time.monotonic()
    absolute_deadline = started_at + absolute_timeout
    read_deadline = started_at + start_timeout
    data = bytearray()

    while True:
        now = time.monotonic()
        wait_for = min(read_deadline, absolute_deadline) - now
        if wait_for <= 0:
            break

        readable, _, _ = select.select([fd], [], [], wait_for)
        if not readable:
            break

        chunk = os.read(fd, 1024 * 1024)
        if not chunk:
            break

        data.extend(chunk)
        # Some clipboard owners send all bytes but retain the transfer pipe.
        read_deadline = time.monotonic() + idle_timeout

    return bytes(data)


def main() -> int:
    data = read_clipboard_data(sys.stdin.buffer.fileno())
    return store_clipboard_data(data)


def store_clipboard_data(data: bytes) -> int:
    if not data:
        return 0

    result = subprocess.run(["/usr/bin/cliphist", "store"], input=data, check=False)
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
