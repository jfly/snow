{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "snowvpn";
  runtimeInputs = with pkgs; [
    wireguard-tools
    libnotify
  ];
  text = ''
    if [ $# -eq 0 ]; then
      # Default to a split vpn.
      type="split"
    else
      type="$1"
    fi

    if [ "$type" != "split" ] && [ "$type" != "full" ]; then
      echo "Unrecognized type: $type" >/dev/stderr
      exit 1
    fi

    dev="snow-$type"
    conf=~/sync/jfly-linux-secrets/vpn/$dev.conf
    if [ "$(ip address show dev "$dev" 2>&1)" = "Device \"$dev\" does not exist." ]; then
      wg-quick up "$conf"
      notify-send "Connected to vpn: $dev"
    else
      wg-quick down "$conf"
      notify-send "Disconnected from vpn: $dev"
    fi
  '';
}
