{ config, pkgs, ... }:
let
  inherit (config.snow) services;
in
{
  services.nginx.package = pkgs.nginx.override { modules = [ pkgs.nginxModules.fancyindex ]; };

  services.data-mesher.settings.host.names = [
    services.manman.sld
    services.media.sld
  ];

  services.nginx.virtualHosts.${services.manman.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      root = ./webroot;
      index = "index.html";
    };
  };

  services.nginx.virtualHosts.${services.media.fqdn} = {
    enableACME = true;
    forceSSL = true;

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
