import ctypes
from dataclasses import dataclass
import time
import datetime as dt
import os
import io
import subprocess


class TimeVal(ctypes.Structure):
    _fields_ = [
        ("tv_sec", ctypes.c_long),
        ("tv_usec", ctypes.c_long),
    ]

    def as_timedelta(self) -> dt.timedelta:
        return dt.timedelta(
            seconds=self.tv_sec,
            microseconds=self.tv_usec,
        )

    def __str__(self) -> str:
        return str(self.as_timedelta().total_seconds())


class InputEvent(ctypes.Structure):
    # Urg, repeating ourselves here to get typing.
    # See https://blag.nullteilerfrei.de/2021/06/20/prettier-struct-definitions-for-python-ctypes/
    time: TimeVal
    type: int
    code: int
    value: int
    _fields_ = [
        ("time", TimeVal),
        ("type", ctypes.c_uint16),
        ("code", ctypes.c_uint16),
        ("value", ctypes.c_int32),
    ]

    def __str__(self):
        return f"<InputEvent time={self.time} type={self.type} code={self.code} value={self.value}>"


@dataclass
class DriverState:
    p: subprocess.Popen
    stdin: io.FileIO
    stdout: io.FileIO


class ToolDriver:
    def __init__(self, command: list[str]):
        self._command = command
        self._driver_state: DriverState | None = None

    def __enter__(self):
        self.start()
        return self

    def __exit__(self, *_args):
        self.stop()

    def start(self):
        assert self._driver_state is None

        p = subprocess.Popen(
            self._command,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            # Disable buffering of stdin/stdout.
            bufsize=0,
        )
        assert isinstance(p.stdin, io.FileIO)
        assert isinstance(p.stdout, io.FileIO)

        # Do not block reads of stdout. This means we'll need to sleep and wait for
        # all the bytes to show up.
        os.set_blocking(p.stdout.fileno(), False)

        self._driver_state = DriverState(
            p=p,
            stdin=p.stdin,
            stdout=p.stdout,
        )

    def stop(self):
        assert self._driver_state is not None

        self._driver_state.p.kill()
        self._driver_state.p.wait()
        self._driver_state.stdout.close()
        self._driver_state.stdin.close()

        self._driver_state = None

    def send_event(self, event: InputEvent):
        assert self._driver_state is not None, "Must start the driver before using it"

        payload = ctypes.string_at(ctypes.byref(event), ctypes.sizeof(event))
        self._driver_state.stdin.write(payload)

    def get_input_event(self, timeout_seconds: float) -> InputEvent | None:
        assert self._driver_state is not None, "Must start the driver before using it"

        response_buffer = bytearray(ctypes.sizeof(InputEvent))
        bytes_read = 0
        start = time.time()
        while bytes_read < len(response_buffer):
            addl_bytes = self._driver_state.stdout.readinto(
                memoryview(response_buffer)[bytes_read:]
            )
            if addl_bytes is not None:
                bytes_read += addl_bytes

            elapsed_seconds = time.time() - start
            if elapsed_seconds > timeout_seconds:
                # We didn't find an input event in the given time window! Return None.
                #
                # Note that we crash if we read part of an event. This shouldn't happen (the
                # timeout should be large enough that there's plenty of time
                # for events to percolate), and it would be really confusing to
                # do anything else.
                assert bytes_read == 0

                return None

        return InputEvent.from_buffer(response_buffer)
