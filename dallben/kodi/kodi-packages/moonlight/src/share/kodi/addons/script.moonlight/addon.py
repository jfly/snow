import subprocess

import xbmcgui

xbmcgui.Dialog().notification(
    heading="Get ready to rumble!",
    message="Connecting to gurgi",
    time=5000,
)

subprocess.check_call(
    [
        "@moonlight@/bin/moonlight",
        "stream",
        # TODO: figure out why moonlight wastes ~6 seconds doing this DNS lookup
        # "gurgi",
        "192.168.1.140",
        "Desktop",  # so-called "app"
        "--resolution",
        "1920x1080",
        "--capture-system-keys",
        "always",  # ensure the windows key gets sent to the host
    ]
)
