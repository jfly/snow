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


def progress_dots(percentage: int, total_dots=10):
    full_count = percentage // 10
    half_full_count = 1 if percentage % 10 >= 5 else 0
    empty_count = total_dots - half_full_count - full_count
    progress = ("●" * full_count) + ("◐" * half_full_count) + ("○" * empty_count)
    thin_space = "\u2009"
    return thin_space.join(progress)


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
        body = progress_dots(0)
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
        body = progress_dots(volume)

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
