{ config, pkgs, ... }:

let
  inherit (pkgs)
    symlinkJoin
    makeWrapper
    stc-cli
    ;

  home = "/home/${config.snow.user.name}";
  syncDir = "${home}/sync";
  configDir = "${home}/.config/syncthing";
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
      inherit configDir;
      overrideDevices = true;

      settings = {
        devices = {
          "fflewddur" = {
            id = "OMHZ67W-HXT6UWE-VDTEKUO-FOPG5BR-R3PAOZE-NOYS42G-2G2W4OU-MYVUEQA";
          };
        };
        folders = {
          "jfly" = {
            id = "etyx6-oh4ft";
            devices = [
              "fflewddur"
            ];
            ignorePerms = false; # By default, Syncthing doesn't sync file permissions, but there are some scripts in here.
            path = "${syncDir}/jfly";
          };
          "jfly-linux-secrets" = {
            id = "jfly-linux-secrets";
            ignorePerms = false; # The files in this directory have very carefully chosen permissions, don't mess with them.
            devices = [
              {
                name = "fflewddur";
                encryptionPasswordFile = config.age.secrets.syncthing-jfly-linux-secrets.path;
              }
            ];
            path = "${syncDir}/jfly-linux-secrets";
          };
          "manman" = {
            id = "amnsl-rxpc2";
            devices = [
              "fflewddur"
            ];
            path = "${syncDir}/manman";
          };
        };
      };
    };
  };

  age.secrets.syncthing-jfly-linux-secrets = {
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBaWUhYQ28wOEdMcVNPaC9Y
      TTFCTmR3bjhNUHgwa05HaXljbVVnS3VNVTI4CjMrV2tZbENWekZlK2FjSDVjOVBz
      MGM4OWZxb3h5b2ZsOEVuQWF1WnlVREEKLS0tIEpFREpYSk5sQ0FoMXhIZWVtMDIv
      V3ZqNGVNUGhwOEdEQnhtZDhiNmFJbEkKAsTd1rVUPuvf+WuLtVwz76EiqDc0DQcE
      z3FlFXEJCoPdI5VrzCi2CcIf7hDZ2h66bHfMMA==
      -----END AGE ENCRYPTED FILE-----
    '';
    mode = "400";
    owner = config.services.syncthing.user;
    group = "root";
  };

  environment.systemPackages = [
    # Add a wrapped version of `stc` that knows where our syncthing `homedir` is.
    (symlinkJoin {
      name = stc-cli.name;
      paths = [ stc-cli ];
      buildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/stc \
            --add-flags "--homedir=${configDir}"
      '';
    })
  ];
}
