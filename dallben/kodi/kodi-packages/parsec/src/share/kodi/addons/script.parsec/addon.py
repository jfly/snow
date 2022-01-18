import subprocess

import xbmcgui

xbmcgui.Dialog().notification(
    heading="Parsec",
    message="Starting Parsec!",
    time=5000,
)

settings = {
    'peer_id': '1xmZ7t6z5geMD0zZcv0zDWlQBsp',
    'client_overlay': '0',
    'client_vsync': '0',
}
settings_str = ":".join(f"{k}={v}" for k, v in settings.items())
subprocess.check_call(["parsecd", settings_str])
