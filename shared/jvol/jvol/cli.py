#!/usr/bin/python3

import argparse
import subprocess
from importlib.resources import files, as_file
from . import pa


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
    volnoti_show(args.stream)


def do_set(args):
    pa.set_volume(args.stream, args.new_volume)
    volnoti_show(args.stream)


def do_show(args):
    volnoti_show(args.stream)


def volnoti_show(stream: pa.Stream):
    volume = pa.volume(stream)
    muted = pa.is_muted(stream)

    volnoti_args = []
    if muted:
        volnoti_args.append("-m")
    else:
        pretty_volume = str(volume) + "%"
        volnoti_args.append(pretty_volume)

    if stream == "sink":
        image = None
    elif stream == "source":
        data_dir = files("jvol.data")
        image = (
            data_dir.joinpath("display-mic-muted.svg")
            if muted
            else data_dir.joinpath("display-mic-not-muted.svg")
        )
    else:
        assert False

    if image:
        with as_file(image) as f:
            volnoti_args = [*volnoti_args, "-s", f]

    subprocess.check_output(["volnoti-show", *volnoti_args])


if __name__ == "__main__":
    main()
