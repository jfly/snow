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
        fancyindex_name_length 255;  # Increase max length before truncation. Note: this option will disappear whenever the next release of fancyindex comes out, see https://github.com/aperezdc/ngx-fancyindex/issues/133#issuecomment-1120508516

        autoindex on;
      '';
    };
  };
}
