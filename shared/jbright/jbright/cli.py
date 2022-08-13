import argparse
import subprocess
from . import brightness
from importlib.resources import files, as_file

devices = brightness.get_devices()

def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(required=True)

    subparser = subparsers.add_parser("set", help="set brightness", add_help=False)
    subparser.add_argument("--device", choices=[d.name for d in devices], default=devices.default.name)
    subparser.add_argument("value")
    subparser.set_defaults(func=do_set)

    subparser = subparsers.add_parser(
        "show", help="show brightness", add_help=False
    )
    subparser.add_argument("--device", choices=[d.name for d in devices], default=devices.default.name)
    subparser.set_defaults(func=do_show)

    args = parser.parse_args()
    args.func(args)

def do_set(args):
    device = devices.get(args.device)
    device.set(args.value)
    volnoti_show(device.percentage_brightness)

def do_show(args):
    device = devices.get(args.device)
    volnoti_show(device.percentage_brightness)

def volnoti_show(percent: float):
    volnoti_args = []

    image = files("jbright.data").joinpath("display-brightness-symbolic.svg")
    with as_file(image) as f:
        volnoti_args = [*volnoti_args, "-s", f]

    volnoti_args.append(str(percent))

    subprocess.check_output(["volnoti-show", *volnoti_args])

if __name__ == "__main__":
    main()
