{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.snow) services;
in
{
  # Gross: xrdp needs access to the ssl certs, but they're owned by acme:nginx.
  # A cleaner alternative would probably be to use systemd's LoadCredential, as
  # we do in home-assistant/mqtt.nix.
  users.users.xrdp.extraGroups = [ "nginx" ];

  # Remote desktop
  services.xrdp = {
    enable = true;
    openFirewall = true;
    # I'm surprised we don't have to configure xrdp to restart when these certs
    # are regenerated. I guess it reads them from disk as needed?
    sslCert = "${config.security.acme.certs.${services.fflewddur.fqdn}.directory}/cert.pem";
    sslKey = "${config.security.acme.certs.${services.fflewddur.fqdn}.directory}/key.pem";
  };

  services.desktopManager.plasma6.enable = true;
  services.xrdp.defaultWindowManager = lib.getExe' pkgs.kdePackages.plasma-workspace "startplasma-x11";

  # Urg, prevent machine from going to sleep.
  # From https://discourse.nixos.org/t/configuring-remote-desktop-access-with-gnome-remote-desktop/48023/3
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  environment.systemPackages = [
    # Useful tool for file deduplication.
    pkgs.czkawka-full

    # Another useful (albeit unfree) tool for file deduplication.
    (pkgs.bcompare.overrideAttrs (oldAttrs: {
      meta = oldAttrs.meta // {
        # This license is a lie. It's just a self-contained way for me to
        # install this software and acknowledge that I'm ok with runnning
        # something unfree.
        license = lib.licenses.apsl20;
      };
    }))

    # Video player.
    pkgs.vlc

    # File browser with "Miller columns".
    pkgs.pantheon.elementary-files

    # Web browser
    pkgs.firefox

    # Advanced search for KDE's dolphin.
    pkgs.kdePackages.kfind
  ];
}
