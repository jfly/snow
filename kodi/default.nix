{ pkgs, ... }:

{
  fileSystems."/mnt/media" = {
    device = "clark:/";
    fsType = "nfs";
  };

  users.users.dallben.extraGroups = [
    "dialout"  # Needed to access /dev/ttyACM0, which is used by libcec. See https://flameeyes.blog/2020/06/25/kodi-nuc-and-cec-adapters/ for details.
  ];

  environment.systemPackages = [
    (
      let
        my_kodi_packages = pkgs.callPackage ./kodi-packages {};
      in
      pkgs.kodi.withPackages (builtin_kodi_packages: [
        builtin_kodi_packages.a4ksubtitles
        my_kodi_packages.media
        my_kodi_packages.autoreceiver
        my_kodi_packages.parsec
      ])
    )
  ];

  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 8080 ];
  };
}
