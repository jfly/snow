{ lib, pkgs, ... }:
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

    # File browser with "Miller columns".
    pkgs.pantheon.elementary-files
  ];
}
