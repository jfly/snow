from dataclasses import dataclass
import sys
import subprocess
from pathlib import Path
import logging
import traceback
import click
from . import highlander_rule
from . import data
from .audio import set_loopback
from . import xrandr
from .util import notify_send
from .util import set_dpi

logger = logging.getLogger(__name__)


class PairingMode:
    @staticmethod
    def message():
        return " Mode: pairing"

    @staticmethod
    def mobile_dpi():
        return 180

    @staticmethod
    def projector_dpi():
        return 150

    @staticmethod
    def apply_audio_tweaks():
        # The delay with loopback is unbearably confusing.
        # set_loopback(True)
        pass


class SoloMode:
    @staticmethod
    def message():
        return " Mode: solo"

    @staticmethod
    def mobile_dpi():
        return 133

    @staticmethod
    def projector_dpi():
        return 96

    @staticmethod
    def apply_audio_tweaks():
        set_loopback(False)


def get_mode():
    if Path("/tmp/pairing").exists():
        return PairingMode
    else:
        return SoloMode


def autoperipherals():
    detected = _detect()
    location_name = detected.location_name
    dpi = detected.dpi
    x = detected.x
    mode = detected.mode

    message = f"Detected location {location_name}."
    message += mode.message()
    notify_send(message)

    todo = {
        # Enable the corresponding systemd target, so special services can run when we're in a specific location.
        # These systemd targets are defined in pattern/desktop/.
        "set-location": lambda: subprocess.run(
            ["systemctl", "start", "--user", f"location-{location_name}.target"],
            check=True,
        ),
        "update-monitors": x.apply,
        # This can fail on boot with this error:
        #  > Translate ID error: '-1' is not a valid ID (returned by default-nodes-api)
        "apply-audio-tweaks": mode.apply_audio_tweaks,
        "setbg": lambda: subprocess.run(["setbg"], check=True),
        "set-dpi": lambda: set_dpi(dpi),
    }

    success = True
    for name, thing in todo.items():
        try:
            thing()
        except subprocess.SubprocessError as e:
            success = False
            print(f"Something went wrong when trying to: {name}", file=sys.stderr)
            traceback.print_exception(e)

    if not success:
        print("Something went wrong. See above for details.", file=sys.stderr)
        sys.exit(1)


@dataclass
class Detection:
    x: xrandr.XRandr
    mode: type[SoloMode] | type[PairingMode]
    location_name: str
    dpi: int


def _detect() -> Detection:
    x = xrandr.XRandr()

    displays = x.connected_displays
    display_by_name = {d.name: d for d in displays}
    display_by_edid_name = {
        f"{d.edid.name} {d.edid.serial}": d for d in displays if d.edid is not None
    }

    mode = get_mode()

    if primary_external := display_by_edid_name.get("DELL U2715H H7YCC8AA0DSS"):
        location_name = "garageman"
        dpi = mode.projector_dpi()

        for display in displays:
            display.is_active = False
        primary_external.is_active = True
        primary_external.is_primary = True

        if secondary_external := display_by_edid_name.get("DELL P2417H KH0NG8BU2HML"):
            secondary_external.is_active = True
            secondary_external.right_of = primary_external
    elif external_display := display_by_name.get("HDMI-1"):
        location_name = "projector"
        dpi = mode.projector_dpi()

        for display in displays:
            display.is_active = False
        external_display.is_active = True
    else:
        location_name = "mobile"
        dpi = mode.mobile_dpi()

        internal_display = display_by_name["eDP-1"]
        for display in displays:
            display.is_active = False
        internal_display.is_active = True

    # Set the rotation for all displays according to whatever we last had saved for them.
    state = data.State.load()
    for display in displays:
        if display.edid_hex is None:
            continue

        if rotation := state.rotation_by_edid_hex.get(display.edid_hex):
            display.rotation = rotation

    return Detection(
        x=x,
        mode=mode,
        location_name=location_name,
        dpi=dpi,
    )


@click.group()
def main():
    pass


@main.command()
def sync():
    logging.basicConfig(level=logging.INFO)

    try:
        with highlander_rule.enforce():
            autoperipherals()
    except highlander_rule.ThereCanBeOnlyOne as e:
        logger.error(
            (
                "Could not obtain lock on %s.\n"
                "Is another autoperipherals script currently running?"
            ),
            e.path,
        )


class NoCurrentDisplayException(click.ClickException):
    exit_code = 3

    def __init__(self):
        super().__init__("Couldn't find current display")


class NoEdidException(click.ClickException):
    exit_code = 4

    def __init__(self, display: xrandr.Display):
        super().__init__(f"Display {display.name} does not seem to have an EDID?")


@main.command()
@click.argument("what", type=click.Choice(["current"]))
@click.argument("rotation", type=xrandr.Rotation)
def rotate(what: str, rotation: xrandr.Rotation):
    logging.basicConfig(level=logging.INFO)

    x = xrandr.XRandr()
    state = data.State.load()

    if what == "current":
        displays = x.get_displays_where_mouse_is()
        if len(displays) == 0:
            raise NoCurrentDisplayException()
        elif len(displays) > 1:
            logger.warning(
                "The cursor appears to simultaneously be on multiple displays"
            )
    else:
        assert False, f"Unrecognized 'what': {what}"

    for display in displays:
        if display.edid_hex is None:
            raise NoEdidException(display)

        state.rotation_by_edid_hex[display.edid_hex] = rotation

    state.save()
    autoperipherals()


if __name__ == "__main__":
    main()
