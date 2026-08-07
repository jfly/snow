{ config, pkgs, ... }:
let
  inherit (config.snow) services;
in
{
  services.nginx.package = pkgs.nginx.override { modules = [ pkgs.nginxModules.fancyindex ]; };

  snow.services.manman.hostedHere = true;
  services.nginx.virtualHosts.${services.manman.fqdn} = {
    locations."/" = {
      root = ./webroot;
      index = "index.html";
    };
  };

  snow.services.media.hostedHere = true;
  services.nginx.virtualHosts.${services.media.fqdn} = {
    locations."/" = {
      root = "/mnt/media";
      index = "index.html";

      extraConfig = ''
        fancyindex on;
        fancyindex_exact_size off;  # Output human-readable file sizes.

        autoindex on;
      '';
    };
  };
}
