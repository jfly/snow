# https://wiki.nixos.org/wiki/Install_NixOS_on_Hetzner_Cloud#Network_configuration

{
  networking.useDHCP = false;
  systemd.network.enable = true;

  systemd.network.networks."30-wan" = {
    matchConfig.Name = "enp1s0";
    networkConfig.DHCP = "no";
    address = [
      "5.78.116.143/32"
      "2a01:4ff:1f0:ad06::/64"
    ];

    routes = [
      {
        Gateway = "172.31.1.1";
        GatewayOnLink = true;
      }
      { Gateway = "fe80::1"; }
    ];
  };
}
