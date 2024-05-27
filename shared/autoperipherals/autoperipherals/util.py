from pathlib import Path
import subprocess


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
