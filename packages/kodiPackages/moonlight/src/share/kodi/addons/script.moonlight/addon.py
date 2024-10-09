import subprocess

import xbmcgui

xbmcgui.Dialog().notification(
    heading="Get ready to rumble!",
    message="Connecting to gurgi",
    time=5000,
)

subprocess.check_call(
    [
        "systemctl",
        "--user",
        "start",
        "moonlight",
    ]
)
