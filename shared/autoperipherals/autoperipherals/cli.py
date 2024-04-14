import errno
import fcntl
import subprocess
import contextlib
from pathlib import Path
import xdg.BaseDirectory
import logging

from .xrandr import XRandr

logger = logging.getLogger(__name__)


def data_dir(file: str) -> Path:
    data_dir = xdg.BaseDirectory.save_data_path("autoperipherals")
    return Path(data_dir) / file


class ThereCanBeOnlyOne(Exception):
    def __init__(self, path: Path):
        self.path = path


@contextlib.contextmanager
def enforce_highlander_rule():
    """
    Make sure that there is only one copy of this tool running at once. If
    there's already another copy running, raises ThereCanBeOnlyOne.
    """
    lockfile_path = data_dir("autoperipherals.lock")
    with open(lockfile_path, "w") as lockfile:
        try:
            fcntl.lockf(lockfile, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError as e:
            # From https://docs.python.org/3/library/fcntl.html#fcntl.lockf:
            # > If LOCK_NB is used and the lock cannot be acquired, an OSError
            # > will be raised and the exception will have an errno attribute set
            # > to EACCES or EAGAIN (depending on the operating system; for
            # > portability, check for both values).
            if e.errno in (errno.EACCES, errno.EAGAIN):
                raise ThereCanBeOnlyOne(lockfile_path)
            raise e

        try:
            yield
        finally:
            fcntl.lockf(lockfile, fcntl.LOCK_UN)


def set_dpi(dpi: int):
    # Change DPI and notify everyone via XSETTINGS.
    # See https://utcc.utoronto.ca/~cks/space/blog/linux/XSettingsNotes?showcomments
    # and https://github.com/GNOME/gtk/blob/1a1373779f87ce928a45a9371512d207445f615f/gdk/x11/xsettings-client.c#L399
    with (Path.home() / ".xsettingsd").open("w") as f:
        f.write(f"Xft/DPI {1024 * dpi}\n")

    # Why check=False? When running on boot, xsettingsd may not even be running
    # yet, and killall will fail if there isn't one.
    subprocess.run(["killall", "-HUP", "xsettingsd"], check=False)

    # Notify alacritty about the font size change, because alacritty doesn't understand the
    # XSETTINGS protocol yet =( See
    # https://github.com/alacritty/alacritty/issues/2886 for details.
    good_96_dpi_font_size = 12
    good_133_dpi_font_size = 14
    rate = (good_133_dpi_font_size - good_96_dpi_font_size) / (133.0 - 96.0)
    font_size = good_96_dpi_font_size + (dpi - 96) * rate
    subprocess.check_call(
        ["with-alacritty", "set", "global", "font.size", str(font_size)]
    )


def notify_send(msg: str):
    # notify-send blocks until something receives the message. When booting,
    # we have not started dunst yet, so we need to run notify-send in the background.
    subprocess.Popen(["notify-send", msg])


def autoperipherals():
    xrandr = XRandr()

    displays = xrandr.connected_displays
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
            secondary_external.rotation = "left"
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
    # These systemd targets are defined in pattern/desktop.nix.
    subprocess.run(
        ["systemctl", "start", "--user", f"location-{location_name}.target"], check=True
    )

    xrandr.apply()

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
    subprocess.run(["setbg"], check=False)

    set_dpi(dpi)


def main():
    logging.basicConfig(level=logging.INFO)

    try:
        with enforce_highlander_rule():
            autoperipherals()
    except ThereCanBeOnlyOne as e:
        logger.error(
            (
                "Could not obtain lock on %s.\n"
                "Is another autoperipherals script currently running?"
            ),
            e.path,
        )


if __name__ == "__main__":
    main()
