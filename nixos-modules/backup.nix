{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.snow.backup;
in
{
  options.snow.backup = {
    enable = lib.mkEnableOption "kodi-colusita";

    resticPasswordEncrypted = lib.mkOption {
      type = lib.types.str;
      description = ''
        Encrypted restic password.
        To generate, run this on fflewddur:

        $ sudo restic -r /mnt/bay/restic key add --host fflewddur
        $ sudo chown -R restic:restic /mnt/bay/restic/keys

        Then encrypt the key with `python -m tools.encrypt`.
      '';
    };

    monitorApiKeyEncrypted = lib.mkOption {
      type = lib.types.str;
      description = ''
        Encrypted monitoring api token.

        Create a new monitor on <https://monitoring.snow.jflei.com/>, copy the
        token from the heartbeat url.

        Then encrypt the token with `python -m tools.encrypt`.
      '';
    };

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = ''
        The paths to backup.
      '';
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = ''
        paths to exclude from the backup.
      '';
      default = [ ];
    };

    backupPrepareCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        A script that must run before starting the backup process.
      '';
    };
  };

  config = {
    age.secrets = {
      restic-password.rooterEncrypted = cfg.resticPasswordEncrypted;
      backup-monitor-api-key.rooterEncrypted = cfg.monitorApiKeyEncrypted;
    };

    services.restic.backups = {
      snow = {
        package = pkgs.restic.overrideAttrs (oldAttrs: {
          patches = oldAttrs.patches ++ [
            # https://github.com/restic/restic/pull/5190 backported to v0.17.3
            (pkgs.fetchpatch {
              name = "fs: error if a symlink points at a file that is not included in the snapshot";
              url = "https://github.com/restic/restic/compare/v0.17.3...jfly:restic:issue-542-backport-0.17.3.diff";
              hash = "sha256-PM9jzIAReC4zjHCq9MTWp5aHr2AY3ttskIx7zB78prM=";
            })
          ];
        });

        backupPrepareCommand = cfg.backupPrepareCommand;

        # Report success!
        backupCleanupCommand = ''
          echo "Reporing success to monitoring.snow.jflei.com"
          ${pkgs.curl}/bin/curl --no-progress-meter "https://monitoring.snow.jflei.com/api/push/$(cat ${config.age.secrets.backup-monitor-api-key.path})?status=up&msg=OK&ping="
        '';

        passwordFile = config.age.secrets.restic-password.path;
        paths = cfg.paths;
        exclude = cfg.exclude;
        repository = "rest:http://fflewddur:8000/";
        timerConfig = {
          OnCalendar = "daily";
        };
      };
    };
  };
}
