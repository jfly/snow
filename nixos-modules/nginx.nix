{ config, ... }:
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
  };

  networking.firewall.interfaces.${config.snow.subnets.overlay.interface}.allowedTCPPorts = [
    80
    443
  ];
}
