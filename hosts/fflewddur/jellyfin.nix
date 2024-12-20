{ config, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    group = "media";
  };
  snow.backup.paths = [ config.services.jellyfin.dataDir ];
}
