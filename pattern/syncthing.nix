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
      devices = {
        "snow" = {
          id = pkgs.deage.string ''
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBLeUxtZlk3OGZyQkMrZzlm
            YjJvRmJOdlZNMU5EakJNOTJZQ2hsdmEvZlMwClNJNkRHQU5QTWhNekQzRzZuTlEx
            bGVDL1Fyd2F2L05jbUUyRzRqdERsclUKLS0tIDViSTVZSHJzejdMdHVEeGg5ZzND
            NmUzUGNncTVTSHhsaVIxc2pCeURCdlkKngDZxrehlssfMTwDxHNkndju4K9i3ObJ
            PBUjBa5TsMS61TxqEquoQb7GX3Rg+tX373//AXsm/ZrbU3H/16SE4GT0P+rAVwpV
            JlK+yfB/Q2E5YI6Pei2kTdENXyZIqe0=
            -----END AGE ENCRYPTED FILE-----
          '';
        };
      };
      folders = {
        "music" = {
          type = "receiveonly";
          id = pkgs.deage.string ''
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBVWVVDWkxBeDNnbER5RFVS
            NTNkRlM4TkZTSVEzVDdrSjlPUVltTkJ6bm4wCmVTbTlUaVYrUWhEMThIZVNUVEJm
            c0N0SW9jY3BwdHZrbHp0bWFRbGtYaTQKLS0tIG1JaFN1ajFDbkZ1VUlWQmVPYllO
            ZlNLVWExV28zZHlqRVNkSjB2WHUyaFkKB0d71Vb1UlmbH03Fzr6SfBGK7M2zRMKz
            opQRNznVTe8LDFMy3wbTusjnBA==
            -----END AGE ENCRYPTED FILE-----
          '';
          path = "${syncDir}/music";
          devices = [ "snow" ]; # Which devices to share the folder with
        };
        "calibre" = {
          id = pkgs.deage.string ''
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBTcjMreGN3NFJIZ0RqN2Nk
            SDc0V24vLzBwbE1FSTI5dGVXSUdWdzdsdENnClI4VnY3WG9EVlo5blpmZFRMS0hH
            TjhKQlhSckJOK0NORyt5aHJVeituU2sKLS0tIGxnclBDNUIzRkN0UEh6cUxHbEhT
            YVFGaE9na3ZycnAyU3NJaGk0TEcxY2sKNXfyiFrQi9bzTd2ca+LMvLr1lGh8y8Ny
            /OF/t7JuvBy+zeIO9g6nQ1cKxQ==
            -----END AGE ENCRYPTED FILE-----
          '';
          devices = [ "snow" ];
          path = "${syncDir}/calibre";
        };
        "scratch" = {
          id = pkgs.deage.string ''
            -----BEGIN AGE ENCRYPTED FILE-----
            YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBCTmJhMHQ2aFdYa2RxRlVj
            eFpWUEpMZHFXSytJKzgzWUhSMUw2bHNQU0Q0CldpYkp5K2dMWXBoWGhWY1RuT0Zk
            dXNGV3dOcytSSkhvYTZjTWZBUEkrL3MKLS0tIDFBUG5OY1ZTSVhFTU1iQWoxVVlh
            VXc0WnB2K25uUFVIMlBRL1lDTzFEdVUKtfXgDzEJv39ePZFn8dqxh+2JdnvuPs69
            OOA2njc8xXPYiQO4bSIU+fVuCQ==
            -----END AGE ENCRYPTED FILE-----
          '';
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
      };
    };
  };
}
