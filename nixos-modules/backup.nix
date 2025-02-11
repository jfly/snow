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
    enable = lib.mkEnableOption "snow-backup";

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
    age.secrets.restic-password.rooterEncrypted = cfg.resticPasswordEncrypted;

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

        backupPrepareCommand =
          ''
            date +%s.%N > $RUNTIME_DIRECTORY/start-ts
          ''
          + (if cfg.backupPrepareCommand != null then cfg.backupPrepareCommand else "");

        # Report success!
        backupCleanupCommand =
          # bash
          ''
            if [ "$SERVICE_RESULT" = "success" ]; then
              start_time=$(cat $RUNTIME_DIRECTORY/start-ts)
              end_time=$(date +%s.%N)
              duration_seconds=$(echo "$end_time - $start_time" | ${lib.getExe pkgs.bc})

              echo "That backup took $duration_seconds seconds. Reporting success to Prometheus"
              echo 'backup_completion_timestamp_seconds{site="snow"}' "$(date +%s)" | ${pkgs.moreutils}/bin/sponge ${config.snow.monitoring.node_textfile_dir}/backup_completion_timestamp_seconds-snow.prom
              echo 'backup_duration_seconds{site="snow"}' "$duration_seconds" | ${pkgs.moreutils}/bin/sponge ${config.snow.monitoring.node_textfile_dir}/backup_duration_seconds-snow.prom
            fi
          '';

        passwordFile = config.age.secrets.restic-password.path;
        paths = cfg.paths;
        exclude = cfg.exclude;
        repository = "rest:http://fflewddur.ec:8000/";
        timerConfig = {
          OnCalendar = "daily";
        };
      };
    };
  };
}
