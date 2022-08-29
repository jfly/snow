import argparse
import subprocess
from . import brightness

EXPIRATION_MILLIS = 2000

devices = brightness.get_devices()


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(required=True)

    subparser = subparsers.add_parser("set", help="set brightness", add_help=False)
    subparser.add_argument(
        "--device", choices=[d.name for d in devices], default=devices.default.name
    )
    subparser.add_argument("value")
    subparser.set_defaults(func=do_set)

    subparser = subparsers.add_parser("show", help="show brightness", add_help=False)
    subparser.add_argument(
        "--device", choices=[d.name for d in devices], default=devices.default.name
    )
    subparser.set_defaults(func=do_show)

    args = parser.parse_args()
    args.func(args)


def do_set(args):
    device = devices.get(args.device)
    device.set(args.value)
    notify_show(device.percentage_brightness)


def do_show(args):
    device = devices.get(args.device)
    notify_show(device.percentage_brightness)


def progress_dots(percentage: int, total_dots=10):
    full_count = percentage // 10
    half_full_count = 1 if percentage % 10 >= 5 else 0
    empty_count = total_dots - half_full_count - full_count
    progress = ("●" * full_count) + ("◐" * half_full_count) + ("○" * empty_count)
    thin_space = "\u2009"
    return thin_space.join(progress)


def notify_show(percent: float):
    pretty_brightness = str(int(percent)) + "%"
    subject = f"Display brightness: {pretty_brightness}"
    body = progress_dots(int(percent))

    brightness_id = sum(ord(ch) for ch in "jbright")
    subprocess.check_output(
        [
            "notify-send",
            f"--replace-id={brightness_id}",
            f"--expire-time={EXPIRATION_MILLIS}",
            "--urgency=low",
            "--transient",
            "--icon=display-brightness",
            subject,
            body,
        ]
    )


if __name__ == "__main__":
    main()
