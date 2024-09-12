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


def notify_show(percent: float):
    pretty_brightness = str(int(percent)) + "%"
    subject = f"Display brightness: {pretty_brightness}"
    body = progress(int(percent))

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
