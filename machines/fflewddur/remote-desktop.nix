{
  lib,
  pkgs,
  inputs',
  ...
}:
{
  # Remote desktop
  services.xrdp.enable = true;
  services.xrdp.openFirewall = true;

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
    # As of 2025-12-26, the latest version has some bugs with gtk: <https://github.com/qarmin/czkawka/issues/1712>
    # I cannot figure out how to run `krokiet`, so we're using an old version
    # of `czkawka` for now.
    inputs'.nixpkgs-25_05.legacyPackages.czkawka-full
    # pkgs.czkawka-full

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
