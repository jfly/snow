{ config, ... }:
let
  inherit (config.snow) services;
in
{
  services.jellyfin = {
    enable = true;
    group = "media";
  };
  snow.backup.paths = [ config.services.jellyfin.dataDir ];

  # TODO: remove jellyfin.snow.jflei.com proxy from k8s
  services.data-mesher.settings.host.names = [ services.jellyfin.sld ];
  services.nginx.virtualHosts.${services.jellyfin.fqdn} = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      # https://jellyfin.org/docs/general/post-install/networking/
      proxyPass = "http://localhost:8096";
    };
  };

  services.nginx.virtualHosts."jellyfin.snow.jflei.com" = {
    enableACME = false;
    forceSSL = false;

    locations."/" = {
      # https://jellyfin.org/docs/general/post-install/networking/
      proxyPass = "http://localhost:8096";
    };
  };
}
