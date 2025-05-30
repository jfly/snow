from pathlib import Path
import subprocess
import logging

logger = logging.getLogger(__name__)


def set_dpi(dpi: int):
    logger.info("Setting DPI to %s", dpi)

    # Change DPI and notify everyone via XSETTINGS.
    # See https://utcc.utoronto.ca/~cks/space/blog/linux/XSettingsNotes?showcomments
    # and https://github.com/GNOME/gtk/blob/1a1373779f87ce928a45a9371512d207445f615f/gdk/x11/xsettings-client.c#L399
    with (Path.home() / ".xsettingsd").open("w") as f:
        f.write(f"Xft/DPI {1024 * dpi}\n")

    # Why `check=False`? When running on boot, xsettingsd may not even be running
    # yet, and killall will fail if there isn't one.
    subprocess.run(["killall", "-HUP", "xsettingsd"], check=False)


def notify_send(msg: str):
    # notify-send blocks until something receives the message. When booting,
    # we have not started dunst yet, so we need to run notify-send in the background.
    subprocess.Popen(["notify-send", msg])
