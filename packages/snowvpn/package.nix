{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "snowvpn";
  runtimeInputs = with pkgs; [
    wireguard-tools
    libnotify
  ];
  text = ''
    if [ "$(ip address show dev snow 2>&1)" = 'Device "snow" does not exist.' ]; then
      wg-quick up ~/sync/jfly-linux-secrets/vpn/snow.conf
      notify-send "Connected to vpn: snow"
    else
      wg-quick down ~/sync/jfly-linux-secrets/vpn/snow.conf
      notify-send "Disconnected from vpn: snow"
    fi
  '';
}
