{ config, ... }:
{
  services.jellyfin = {
    enable = true;
    group = "media";
  };

  systemd.services.jellyfin = {
    unitConfig = {
      RequiresMountsFor = "/mnt/media";
    };
  };

  snow.backup.paths = [ config.services.jellyfin.dataDir ];

  # https://jellyfin.org/docs/general/post-install/networking/
  snow.services.jellyfin.proxyPass = "http://localhost:8096";
}
