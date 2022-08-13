#!/usr/bin/python3

import subprocess
from typing import Literal

Stream = Literal["sink", "source"]


def _pamixer(args):
    p = subprocess.run(["pamixer", *args], text=True, stdout=subprocess.PIPE)
    return p.stdout


def _pamixer_stream(stream: Stream, args):
    addl_args = {
        "source": ["--default-source"],
        "sink": [],
    }[stream]
    return _pamixer([*addl_args, *args])


def volume(stream: Stream):
    return int(_pamixer_stream(stream, ["--get-volume"]).strip())


def set_volume(stream: Stream, new_volume: str):
    if new_volume.endswith("%+"):
        delta = int(new_volume.removesuffix("%+"))
        _pamixer_stream(stream, ["--increase", str(delta)])
    elif new_volume.endswith("%-"):
        delta = int(new_volume.removesuffix("%-"))
        _pamixer_stream(stream, ["--decrease", str(delta)])
    else:
        _pamixer_stream(stream, ["--set-volume", str(new_volume)])


def is_muted(stream: Stream):
    return _pamixer_stream(stream, ["--get-mute"]).strip() == "true"


def set_mute(stream: Stream, mute):
    _pamixer_stream(stream, ["--mute" if mute else "--unmute"])


def toggle(stream: Stream):
    _pamixer_stream(stream, ["--toggle-mute"])
