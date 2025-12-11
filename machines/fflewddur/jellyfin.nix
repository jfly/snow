{ config, ... }:
{
  services.jellyfin = {
    enable = true;
    group = "media";
  };
  snow.backup.paths = [ config.services.jellyfin.dataDir ];

  # https://jellyfin.org/docs/general/post-install/networking/
  snow.services.jellyfin.proxyPass = "http://localhost:8096";

  # TODO: remove jellyfin.snow.jflei.com proxy from k8s
  services.nginx.virtualHosts."jellyfin.snow.jflei.com" = {
    enableACME = false;
    forceSSL = false;

    locations."/" = {
      # https://jellyfin.org/docs/general/post-install/networking/
      proxyPass = "http://localhost:8096";
    };
  };
}
