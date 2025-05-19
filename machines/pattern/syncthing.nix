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
                encryptionPasswordFile = config.clan.core.vars.generators.syncthing.files."jfly-linux-secrets".path;
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

  clan.core.vars.generators.syncthing = {
    files."jfly-linux-secrets" = {
      mode = "0400";
      owner = config.services.syncthing.user;
      group = "root";
    };
    prompts.jfly-linux-secrets = {
      type = "hidden";
    };
    script = ''
      cp $prompts/jfly-linux-secrets $out/jfly-linux-secrets
    '';
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
