{ config, pkgs, ... }:

let
  home = "/home/${config.snow.user.name}";
  syncDir = "${home}/sync";
in
{
  services = {
    syncthing = {
      enable = true;
      user = config.snow.user.name;
      dataDir = syncDir;
      extraFlags = [
        # Prevent creation of ~/Sync directory on first startup. We don't use
        # it for anything, and it's confusing to have living next to the ~/sync
        # directory.
        "--no-default-folder"
      ];
      configDir = "${home}/.config/syncthing";
      overrideDevices = true;
      overrideFolders = true;
      settings = {
        devices = {
          "snow" = {
            id = "D3NFS4D-DHERIM7-T62ZVKD-RE6T37K-MCYWHDE-CHH56RW-E6KN4HF-TDWVXAR";
          };
        };
        folders = {
          "music" = {
            type = "receiveonly";
            id = "wgvgw-yqwcq";
            path = "${syncDir}/music";
            devices = [ "snow" ]; # Which devices to share the folder with
          };
          "calibre" = {
            id = "ahnvm-wqudj";
            devices = [ "snow" ];
            path = "${syncDir}/jeremy/books/calibre";
          };
          "scratch" = {
            id = "etyx6-oh4ft";
            devices = [ "snow" ];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions, but there are some scripts in here.
            path = "${syncDir}/scratch";
          };
          "wallpaper" = {
            devices = [ "snow" ];
            path = "${syncDir}/wallpaper";
          };
          "linux-secrets" = {
            devices = [ "snow" ];
            ignorePerms = false; # The files in this directory have very carefully chosen permissions, don't mess with them.
            path = "${syncDir}/linux-secrets";
          };
          "manman" = {
            id = "amnsl-rxpc2";
            devices = [ "snow" ];
            path = "${syncDir}/manman";
          };
        };
      };
    };
  };
}
