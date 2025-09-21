from contextlib import contextmanager
import pulsectl
import dbus

# Names from `nix-shell -p pulseaudio --run 'pactl list sinks | grep "Name:\|Description:"'`
DESK_SPEAKERS = (
    "alsa_output.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.HiFi__HDMI1__sink"
)
GAMING_HEADSET = (
    "alsa_output.usb-Kingston_HyperX_Cloud_Flight_S_000000000001-00.analog-stereo"
)


@contextmanager
def with_pulse():
    pulse = pulsectl.Pulse("default")
    try:
        yield pulse
    finally:
        pulse.close()


def notify(summary: str, body: str):
    # Inspired by https://pychao.com/2021/03/01/sending-desktop-notification-in-linux-with-python-with-d-bus-directly/
    # Docs for this interface are here: https://specifications.freedesktop.org/notification-spec/notification-spec-latest.html#command-notify
    item = "org.freedesktop.Notifications"
    notfy_interface = dbus.Interface(
        dbus.SessionBus().get_object(item, "/" + item.replace(".", "/")), item
    )

    app_name = ""
    replaces_id = 0  # "A value of value of 0 means that this notification won't replace any existing notifications."
    app_icon = "audio-card"  # "Can be an empty string, indicating no icon." https://specifications.freedesktop.org/notification-spec/notification-spec-latest.html#icons-and-images
    actions = []
    hints = {}  # https://specifications.freedesktop.org/notification-spec/notification-spec-latest.html#hints
    visible_duration_ms = -1  # "If -1, the notification's expiration time is dependent on the notification server's settings, and may vary for the type of notification. If 0, never expire."
    notfy_interface.Notify(
        app_name,
        replaces_id,
        app_icon,
        summary,
        body,
        actions,
        hints,
        visible_duration_ms,
    )


def main():
    with with_pulse() as pulse:
        server_info = pulse.server_info()
        default_sink_name = server_info.default_sink_name
        if default_sink_name == DESK_SPEAKERS:
            notify(
                "Audio switcher", "Desk speakers detected. Switching to gaming headset."
            )
            new_sink = pulse.get_sink_by_name(GAMING_HEADSET)
            pulse.default_set(new_sink)
        elif default_sink_name == GAMING_HEADSET:
            notify(
                "Audio switcher", "Gaming headset detected. Switching to desk speakers."
            )
            new_sink = pulse.get_sink_by_name(DESK_SPEAKERS)
            pulse.default_set(new_sink)
        else:
            sink = pulse.get_sink_by_name(default_sink_name)
            notify(
                "Audio switcher",
                f"Unrecognized default sink: {default_sink_name} ({sink.description}). I'm not sure what to do to it.",
            )


if __name__ == "__main__":
    main()
