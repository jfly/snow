#!/usr/bin/python3

import argparse
import subprocess
from . import pa

EXPIRATION_MILLIS = 2000


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(required=True)

    subparser = subparsers.add_parser(
        "toggle", help="toggle the given PulseAudio stream", add_help=False
    )
    subparser.add_argument("stream", choices=["sink", "source"])
    subparser.set_defaults(func=do_toggle)

    subparser = subparsers.add_parser("set", help="set volume", add_help=False)
    subparser.add_argument("stream", choices=["sink", "source"])
    subparser.add_argument("new_volume")
    subparser.set_defaults(func=do_set)

    subparser = subparsers.add_parser(
        "show", help="show volume for the given stream", add_help=False
    )
    subparser.add_argument("stream", choices=["sink", "source"])
    subparser.set_defaults(func=do_show)

    args = parser.parse_args()
    args.func(args)


def do_toggle(args):
    pa.toggle(args.stream)
    notify_show(args.stream)


def do_set(args):
    pa.set_volume(args.stream, args.new_volume)
    notify_show(args.stream)


def do_show(args):
    notify_show(args.stream)


def clamp(val, min_val, max_val):
    assert max_val >= min_val
    if val > max_val:
        return max_val
    elif val < min_val:
        return min_val
    else:
        return val


def progress(percentage: int, total_dots=10):
    chars = ["○", "◐", "●"]

    n_dots_full = (total_dots * percentage) / 100

    def char(i):
        full_ratio = clamp(n_dots_full - i, 0, 1)
        return chars[int(full_ratio * (len(chars) - 1))]

    return "".join(char(i) for i in range(total_dots))


def notify_show(stream: pa.Stream):
    volume = pa.volume(stream)
    muted = pa.is_muted(stream)

    icon = None
    if muted:
        icon = {
            "sink": "audio-volume-muted",
            # Unfortunately, there is no "muted microphone" icon =(
            "source": "audio-input-microphone",
        }[stream]
        subject = "Volume: muted"
        body = progress(0)
    else:
        if stream == "source":
            # Unfortunately, there are no low/medium/high microphone icons =(
            icon = "audio-input-microphone"
        else:
            # Thresholds and icons carefully chosen to match pasystray.
            if volume == 0:
                icon = "audio-volume-muted"
            elif volume <= 30:
                icon = "audio-volume-low"
            elif volume < 70:
                icon = "audio-volume-medium"
            else:
                icon = "audio-volume-high"

        pretty_volume = str(volume) + "%"
        subject = f"Volume: {pretty_volume}"
        body = progress(volume)

    volume_id = sum(ord(ch) for ch in "jvol")
    subprocess.check_output(
        [
            "notify-send",
            f"--replace-id={volume_id}",
            f"--expire-time={EXPIRATION_MILLIS}",
            "--urgency=low",
            "--transient",
            f"--icon={icon}",
            subject,
            body,
        ]
    )


if __name__ == "__main__":
    main()
