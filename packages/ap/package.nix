{
  writeShellApplication,
  iw,
  linux-wifi-hotspot,
}:

writeShellApplication {
  name = "ap";
  runtimeInputs = [
    linux-wifi-hotspot
    iw
  ];

  text = ''
    # Validate command line arguments
    print_usage_and_exit() {
        echo -n "Usage: $0 [password]"
        echo
        exit
    }
    if [ $# -lt 1 ]; then
        print_usage_and_exit
    fi

    dev=wlp0s20f3
    password=$1

    # Some wifi cards (including mine) only support broadingcasting an AP on
    # the same Wifi channel that they're already connected to.
    # See <https://serverfault.com/questions/966352/hostapd-not-working-anymore>
    # Unfortunately, `linux-wifi-hotspot` isn't smart enough to detect this,
    # it'll just use its default channel (1), and fail in an obscure way. See:
    # - https://github.com/lakinduakash/linux-wifi-hotspot/issues/344
    # - https://github.com/lakinduakash/linux-wifi-hotspot/pull/450
    #
    # Here, we attempt to detect the current channel we're connected to
    # (assuming we're connect to wifi at all).
    if ! channel=$(iw "$dev" info | grep -oP '(?<=channel )[0-9]+'); then
        echo "Warning: could not discover current wifi channel. Are you connected to wifi?" >&2
        channel=1
        echo "Falling back to channel $channel" >&2
        echo "" >&2
        echo "" >&2
    fi

    sudo create_ap "$dev" "$dev" "$(hostname)ap" "$password" -c "$channel"
  '';
}
