{ config, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "media";
  };
  snow.backup.paths = [ config.services.jellyfin.dataDir ];

  # TODO: remove jellyfin.snow.jflei.com proxy from k8s
  services.data-mesher.settings.host.names = [ "jellyfin" ];
  services.nginx.virtualHosts."jellyfin.mm" = {
    enableACME = true;
    forceSSL = true;

    locations."/" = {
      # https://jellyfin.org/docs/general/post-install/networking/
      proxyPass = "http://localhost:8096";
    };
  };
}
