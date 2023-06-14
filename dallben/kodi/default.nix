{ config, pkgs, ... }:

let
  myKodiPackages = pkgs.callPackage ./kodi-packages {
    inherit config;
  };
  myKodiWithPackages = pkgs.kodi.withPackages (builtin_kodi_packages: [
    builtin_kodi_packages.a4ksubtitles
    builtin_kodi_packages.joystick
    myKodiPackages.media
    myKodiPackages.autoreceiver
    myKodiPackages.parsec
    myKodiPackages.tubecast
  ]);
  # This is unfortunate: it just doesn't seem to be possible to set some kodi
  # settings without creating files in the ~/.kodi/userdata/addon_data
  # directory. So, we wrap kodi to give us an opportunity to do that.
  genKodiAddonData = pkgs.callPackage ./gen-kodi-addon-data { };
  myKodi = pkgs.symlinkJoin {
    name = "kodi";
    paths = [ myKodiWithPackages ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/kodi \
        --run "${genKodiAddonData}/gen-kodi-addon-data.sh"
    '';
  };

  wait-for-mysql = pkgs.writeShellApplication {
    name = "wait-for-mysql";

    runtimeInputs = [
      pkgs.iputils
      pkgs.mysql-client
    ];

    text = ''
      host=$1
      # Note we're doing the `ping -4` here as well as the `mysqladmin ping`.
      # For some reason, even if the `mysqladmin ping` succeeds, we sometimes
      # see kodi go on to fail to connect to the mysql server. I see in the
      # connection logs that kodi is using ipv4 when it fails to connect to the
      # mysql server. Wild-ass guess: maybe `mysqladmin ping` is using ipv6 and
      # perhaps the ipv6 network is coming up before the ipv4 network?
      until ping -4 -c1 "$host" >/dev/null 2>&1 && mysqladmin ping -h"$host" --silent; do
        echo "Waiting to connect to mysql server: $host..."
        sleep 1
      done
      echo "Successfully pinged mysql server: $host!"
    '';
  };
in
{
  fileSystems."/mnt/media" = {
    device = "fflewddur:/";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.requires=network-online.target"
    ];
  };

  users.users.${config.variables.kodiUsername}.extraGroups = [
    # Needed to access /dev/ttyACM0, which is used by libcec. See
    # https://flameeyes.blog/2020/06/25/kodi-nuc-and-cec-adapters/ for details.
    "dialout"
  ];

  environment.systemPackages = [ myKodi ];

  systemd.user.services = {
    "kodi" = {
      enable = true;
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig = {
        # Don't start up kodi until we think we can connect to the remote mysql
        # server.
        # Note: keep this in sync with the mysql server in dallben/kodi/kodi-packages/media/src/share/kodi/system/advancedsettings.xml
        ExecStartPre = "${wait-for-mysql}/bin/wait-for-mysql clark";
        ExecStart = "${myKodi}/bin/kodi";
      };
    };
  };
}
