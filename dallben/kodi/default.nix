{ config, pkgs, secrets, ... }:

let
  my_kodi_packages = pkgs.callPackage ./kodi-packages {
    inherit config;
    inherit secrets;
  };
  my_kodi_with_packages = pkgs.kodi.withPackages (builtin_kodi_packages: [
    builtin_kodi_packages.a4ksubtitles
    builtin_kodi_packages.joystick
    my_kodi_packages.media
    my_kodi_packages.autoreceiver
    my_kodi_packages.parsec
    my_kodi_packages.tubecast
  ]);
  # This is unfortunate: it just doesn't seem to be possible to set some kodi
  # settings without creating files in the ~/.kodi/userdata/addon_data
  # directory. So, we wrap kodi to give us an opportunity to do that.
  genKodiAddonData = pkgs.callPackage ./gen-kodi-addon-data {
    inherit secrets;
  };
  my_kodi = pkgs.symlinkJoin {
    name = "kodi";
    paths = [ my_kodi_with_packages ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/kodi \
        --run "${genKodiAddonData}/gen-kodi-addon-data.sh"
    '';
  };
in
{
  fileSystems."/mnt/media" = {
    device = "clark:/";
    fsType = "nfs";
  };

  users.users.${config.variables.kodiUsername}.extraGroups = [
    # Needed to access /dev/ttyACM0, which is used by libcec. See
    # https://flameeyes.blog/2020/06/25/kodi-nuc-and-cec-adapters/ for details.
    "dialout"
  ];

  environment.systemPackages = [ my_kodi ];
}
