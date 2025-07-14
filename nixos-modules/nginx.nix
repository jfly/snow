{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
  };
  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
