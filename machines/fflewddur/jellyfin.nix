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

  # https://jellyfin.org/docs/general/post-install/networking/
  snow.services.jellyfin.proxyPass = "http://localhost:8096";
  snow.services.jf.proxyPass = "http://localhost:8096";
}
