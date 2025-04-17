{
  config,
  pkgs,
  lib,
  ...
}:

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

      # We can't enable `overrideFolders` as it removes the encrypted folders
      # we add below (see `syncthing-add-encrypted-folders` below). We could fix this,
      # but it's probably not worth the effort (we should just get support for
      # encrypted folders merged upstream instead).
      overrideFolders = false;

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

  # The NixOS syncthing module doesn't have support for encrypted folders yet.
  # I hacked this systemd unit together by copying swaths of code from
  # `nixpkgs` (`nixos/modules/services/networking/syncthing.nix`). It works-ish
  # (see note above about `overrideFolders`), but hopefully we can get rid of
  # it someday. It looks like there's a chance that upstream will support this
  # someday, see
  # https://github.com/NixOS/nixpkgs/issues/121286 and
  # https://github.com/NixOS/nixpkgs/pull/205653.
  systemd.services.syncthing-add-encrypted-folders =
    let
      cfg = config.services.syncthing;
      curlAddressArgs = path: "${cfg.guiAddress}${path}";
      baseAddress = curlAddressArgs "/rest/config/folders";
      folderCfg = {
        id = "jfly-linux-secrets";
        label = "jfly-linux-secrets";
        ignorePerms = false; # The files in this directory have very carefully chosen permissions, don't mess with them.
        path = "${syncDir}/jfly-linux-secrets";
        devices = [
          {
            deviceId = cfg.settings.devices."fflewddur".id;
            encryptionPassword = "@LINUX_SECRETS_PASSPHRASE@";
          }
        ];
      };
    in
    {
      description = "Syncthing configuration encryption updater";
      requisite = [ "syncthing.service" ];
      after = [ "syncthing.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = cfg.user;
        RemainAfterExit = true;
        RuntimeDirectory = "syncthing-init";
        Type = "oneshot";
        ExecStart = pkgs.writers.writeBash "merge-syncthing-config" ''
          set -efu

          # be careful not to leak secrets in the filesystem or in process listings
          umask 0077

          curl() {
              # get the api key by parsing the config.xml
              while
                  ! ${pkgs.libxml2}/bin/xmllint \
                      --xpath 'string(configuration/gui/apikey)' \
                      ${cfg.configDir}/config.xml \
                      >"$RUNTIME_DIRECTORY/api_key"
              do sleep 1; done
              (printf "X-API-Key: "; cat "$RUNTIME_DIRECTORY/api_key") >"$RUNTIME_DIRECTORY/headers"
              ${pkgs.curl}/bin/curl -sSLk -H "@$RUNTIME_DIRECTORY/headers" \
                  --retry 1000 --retry-delay 1 --retry-all-errors \
                  "$@"
          }

          payload=${lib.escapeShellArg (builtins.toJSON folderCfg)}
          payload=''${payload/@LINUX_SECRETS_PASSPHRASE@/$(cat ${config.age.secrets.syncthing-jfly-linux-secrets.path})}
          curl -d "$payload" -X POST ${baseAddress}
        '';
      };
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
