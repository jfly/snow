import subprocess
import logging
import click
from . import highlander_rule
from . import data
from . import xrandr
from .util import notify_send
from .util import set_dpi

logger = logging.getLogger(__name__)


def autoperipherals():
    x = xrandr.XRandr()

    displays = x.connected_displays
    display_by_name = {d.name: d for d in displays}
    display_by_edid_name = {
        f"{d.edid.name} {d.edid.serial}": d for d in displays if d.edid is not None
    }

    if primary_external := display_by_edid_name.get("DELL U2715H H7YCC8AA0DSS"):
        location_name = "garageman"
        dpi = 96

        for display in displays:
            display.is_active = False
        primary_external.is_active = True
        primary_external.is_primary = True

        if secondary_external := display_by_edid_name.get("DELL P2417H KH0NG8BU2HML"):
            secondary_external.is_active = True
            secondary_external.right_of = primary_external
    elif external_display := display_by_name.get("HDMI-1"):
        location_name = "projector"
        dpi = 96

        for display in displays:
            display.is_active = False
        external_display.is_active = True
    else:
        location_name = "mobile"
        dpi = 133

        internal_display = display_by_name["eDP-1"]
        for display in displays:
            display.is_active = False
        internal_display.is_active = True

    notify_send(f"Detected location {location_name}")

    # Enable the corresponding systemd target, so special services can run when we're in a specific location.
    # These systemd targets are defined in pattern/desktop/.
    subprocess.run(
        ["systemctl", "start", "--user", f"location-{location_name}.target"],
        # The call to `systemctl start` seems to fail on boot with the following message:
        #   > Failed to connect to bus: No medium found
        # This is likely related to the setbg bug described below, which we should fix.
        #
        # Furthermore if anything in
        # 'services.xserver.displayManager.setupCommands' fails, it prevents x11
        # from starting up entirely. So, we should only crash if things are really
        # broken.
        check=False,
    )

    # Set the rotation for all displays according to whatever we last had saved for them.
    state = data.State.load()
    for display in displays:
        if display.edid_hex is None:
            continue

        if rotation := state.rotation_by_edid_hex.get(display.edid_hex):
            display.rotation = rotation

    x.apply()

    subprocess.run(
        ["setbg"],
        # setbg can fail for a couple of reasons:
        #  - autoperipherals gets called as root when booting (we can and should
        #    fix this), and root doesn't have a collection of wallpaper
        #  - on a freshly provisioned machine, ~/sync/wallpaper doesn't exist until
        #    after we've set up syncthing.
        #
        # Furthermore if anything in
        # 'services.xserver.displayManager.setupCommands' fails, it prevents x11
        # from starting up entirely. So, we should only crash if things are really
        # broken.
        check=False,
    )

    set_dpi(dpi)


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
