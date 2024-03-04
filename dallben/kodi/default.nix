{ config, pkgs, ... }:

let
  myKodiPackages = pkgs.callPackage ./kodi-packages { };
  myKodi = pkgs.kodi.withPackages (builtin_kodi_packages: [
    builtin_kodi_packages.a4ksubtitles
    builtin_kodi_packages.joystick
    myKodiPackages.autoreceiver
    myKodiPackages.moonlight
    myKodiPackages.tubecast
  ]);
  # This is unfortunate: it just doesn't seem to be possible to set some kodi
  # settings without creating files in the ~/.kodi/userdata/addon_data
  # directory. So, we wrap kodi to give us an opportunity to do that.
  genKodiAddonData = pkgs.callPackage ./gen-kodi-addon-data {
    ytApiKeyFile = config.age.secrets.yt-api-key.path;
    ytClientIdFile = config.age.secrets.yt-client-id.path;
    ytClientSecretFile = config.age.secrets.yt-client-secret.path;
    mysqlPasswordFile = config.age.secrets.mysql-password.path;
    hostName = config.networking.hostName;
    timeZone = config.time.timeZone;
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
  # Generated by following the instructions on
  # https://github.com/jdf76/plugin.video.youtube/wiki/Personal-API-Keys
  age.secrets.yt-api-key = {
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB0Qlh2aGdoTVB3S0NodDht
      ME1yTVZXdVd1TmdWVXRWVGlaOVN1alM0eldNClZMaVZHRWpIVmY3MjFLNzRhdTlF
      dHhwajNmQ3V3OEJoVWE0UENYZFBzcW8KLS0tIGdZQ1Iyc2UvUDEweGhNeTdXNWpX
      WExNcXEwbHM0QkU5YmxGazBSZUl1RFkKGqKAcgUqRYI0fHjXXN3QZ5KrO6mMRTOo
      wOXTjOEJVq8iLou6T1pZmKzNSD0uOkzllpf4si/by78z6FwNvtOslTRhzlvNrVI=
      -----END AGE ENCRYPTED FILE-----
    '';
    owner = "dallben";
    group = "users";
  };
  age.secrets.yt-client-id = {
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSB5eU1kVGxKWFNVcnFVODkv
      YnpBZ2hyRUhzZFd6NGQyYWVZUjV4dXJsVEdzClA2RGZwQnVUZ2ZWVEw5a295TUdz
      ZDA3b1FDQzJtNGpWS0lrTjJ1M3JHeE0KLS0tIGtLcytWblZtZWdMTXZ6dWlPTUhI
      UFF3SFJsRXFXMzM4aHkrVVNPSThYamsK+b60QUiLQOEj8w2HOGDkgkwrOqBT40TF
      /ynhG+WNyoLFRhWGeSqpSR8HUtrlvU1w+LL7MaZkbg4r5ifu3pYk3laWcn2JHfIT
      DI4Y0HWMLSiZbed5oDIZo+upilWGYDYcrPNXj4b2ESU=
      -----END AGE ENCRYPTED FILE-----
    '';
    owner = "dallben";
    group = "users";
  };
  age.secrets.yt-client-secret = {
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBUU0tvcWVteSswWERRSHVi
      QTU1SGdUUmVnOEJZZ1NCYVRVcE1jSnhlajBFCmZzTzdnQjRLNEF4TVJySU00Qlh0
      bS9VRHpFV2EzMG9IWXpET1FCYURIVHcKLS0tIGQxL0FxR2tWWEJJVW5uaWE0RFZF
      RzIya1ppbXpvVjVrOXdPQXhFOUV5RUkKwGLVZnmlIK9APmOjFRla9buFg7hmcfti
      hCh5mTe29yYc1gKmnEpUODa4nfu9+/ilIHthAv9Tn5k=
      -----END AGE ENCRYPTED FILE-----
    '';
    owner = "dallben";
    group = "users";
  };
  age.secrets.mysql-password = {
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBzT2ZSam0yaTdWOEVZajUr
      ZWpGRnM3Qm5pdXVFK0xJVWFKWkM1Sk5sR1ZRCm8rRkhRaHhUUTg0aHQ2cVpxUk1s
      R0c1NHJWcFVrOWE0ZTRpazFlNU11ZTgKLS0tIFZUSXh2MEpwSXdXZWRXWlBIKzl3
      VGF0MTNMbU9OemFGdWkvdEVhOE5CYkUKkWljWikH8BKbUzosyhQ9gwBc7L8qoaHj
      ECZiuKMrOlfbWq+6/eI8mtEs/MP9U7E=
      -----END AGE ENCRYPTED FILE-----
    '';
    owner = "dallben";
    group = "users";
  };

  fileSystems."/mnt/media" = {
    device = "fflewddur:/";
    fsType = "nfs";
    options = [
      "ro" # readonly
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
      preStart = ''
        ${genKodiAddonData}/gen-kodi-addon-data.sh

        # Don't start up kodi until we think we can connect to the remote mysql
        # server.
        # Note: keep this in sync with the mysql server in dallben/kodi/kodi-packages/media/src/share/kodi/system/advancedsettings.xml
        ${wait-for-mysql}/bin/wait-for-mysql clark
      '';
      serviceConfig = {
        ExecStart = "${myKodi}/bin/kodi";
      };
    };
  };
}
