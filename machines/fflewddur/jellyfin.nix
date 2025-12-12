{ config, ... }:
{
  services.jellyfin = {
    enable = true;
    group = "media";
  };
  snow.backup.paths = [ config.services.jellyfin.dataDir ];

  # https://jellyfin.org/docs/general/post-install/networking/
  snow.services.jellyfin.proxyPass = "http://localhost:8096";
  snow.services.jellyfin-public.proxyPass = "http://localhost:8096";
}
