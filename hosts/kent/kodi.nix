{ flake, ... }:

{
  imports = [
    flake.nixosModules.kodi-colusita
  ];

  networking.firewall.allowedTCPPorts = [
    8080 # Web server
    9090 # JSON/RPC
  ];
  networking.firewall.allowedUDPPorts = [
    9777 # Event Server
  ];

  services.kodi-colusita = {
    enable = true;
    startOnBoot = true;
  };
}
