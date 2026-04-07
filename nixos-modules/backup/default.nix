{
  config,
  inputs',
  lib,
  pkgs,
  ...
}:

let
  inherit (config.snow) services;

  cfg = config.snow.backup;
  resticRepository = "rest:http://${services.fflewddur.fqdn}:8000/";
in
{
  imports = [
    ./postgresql.nix
  ];

  options.snow.backup = {
    enable = lib.mkOption {
      type = lib.types.bool;
      # Yes, this is a strange default for a NixOS module, but I really want it
      # to be hard to forgot to enable backups!
      default = true;
    };

    extraPaths = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      description = ''
        Additional paths to backup.
      '';
    };

    backupPrepareCommands = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        A script that must run before starting the backup process.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs'.systemctl-restore.packages.default
    ];

    # This is still tedious. TODO: look into clan's native support for backups instead.
    clan.core.vars.generators.snow-backup-restic = {
      prompts."password" = {
        description = ''
          Restic password.
          To generate, run this on fflewddur:

          $ sudo restic -r /mnt/bay/restic key add --host ${config.networking.hostName}
          $ sudo chown -R restic:restic /mnt/bay/restic/keys
        '';
        type = "hidden";
        persist = true;
      };
    };

    services.restic.backups = {
      snow = {
        # TODO: revisit this. doesn't feel like this PR is likely to land. also probably need some mechanism for exceptions.
        # package = pkgs.restic.overrideAttrs (oldAttrs: {
        #   patches = oldAttrs.patches ++ [
        #     # https://github.com/restic/restic/pull/5190 backported to v0.17.3
        #     (pkgs.fetchpatch {
        #       name = "fs: error if a symlink points at a file that is not included in the snapshot";
        #       url = "https://github.com/restic/restic/pull/5190.patch";
        #       hash = "sha256-2tQT29MNo0LAZVO0isUzVlPkU31MAti55vh1mCwGrI0=";
        #     })
        #   ];
        # });

        backupPrepareCommand = ''
          date +%s.%N > $RUNTIME_DIRECTORY/start-ts
          ${cfg.backupPrepareCommands}
        '';

        # Report success!
        backupCleanupCommand =
          # bash
          ''
            if [ "$SERVICE_RESULT" = "success" ]; then
              start_time=$(cat $RUNTIME_DIRECTORY/start-ts)
              end_time=$(date +%s.%N)
              duration_seconds=$(echo "$end_time - $start_time" | ${lib.getExe pkgs.bc})

              echo "That backup took $duration_seconds seconds. Reporting success to Prometheus"
              echo 'backup_completion_timestamp_seconds{site="snow"}' "$(date +%s)" | ${pkgs.moreutils}/bin/sponge ${config.snow.monitoring.nodeTextfileDir}/backup_completion_timestamp_seconds-snow.prom
              echo 'backup_duration_seconds{site="snow"}' "$duration_seconds" | ${pkgs.moreutils}/bin/sponge ${config.snow.monitoring.nodeTextfileDir}/backup_duration_seconds-snow.prom
            fi
          '';

        passwordFile = config.clan.core.vars.generators.snow-backup-restic.files."password".path;
        paths = [
          # Programs should store their state here. If they don't, try to fix
          # that rather than adding more paths to back up.
          "/var/lib"

          # Transactionally consistent backups (such as postgres dumps) get
          # placed here. Consider getting rid of this once we're all in on ZFS
          # and can take filesystem snapshots?
          "/var/backup"
        ]
        ++ cfg.extraPaths;
        repository = resticRepository;
        timerConfig = {
          OnCalendar = "daily";
        };
      };
    };
  };
}
