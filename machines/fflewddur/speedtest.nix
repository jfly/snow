{ config, flake, ... }:
{
  imports = [ flake.nixosModules.librespeed ];

  services.librespeed.enable = true;

  services.nginx.virtualHosts."speedtest.snow.jflei.com" = {
    enableACME = false;
    forceSSL = false;

    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.librespeed.port}";
    };
  };
}
