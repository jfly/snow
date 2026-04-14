# This is a modified version of <machines/fflewddur/backup/hetzner.nix>. It
# uses `rsync` instead of `rclone`in order to create truly identical
# filesystems (as far as I can tell, `rclone` cannot faithfully replicate
# symlinks on the remote).
{
  pkgs,
  config,
  lib,
  flake,
  ...
}:
let
  backupPaths = [
    "/mnt/bay/archive/"
    "/mnt/bay/media/"
    "/mnt/bay/restic/"
  ];

  keypair = {
    privateKeyfile = config.clan.core.vars.generators.fflewddur-fflam-backup-ssh.files."key".path;
  };
  box = {
    user = "root";
    host = "fflam.m";
    port = 22;
  };
  ensureTrailingSlash =
    path:
    let
      endsInSlash = (lib.strings.match ".*/$" path) != null;
    in
    if endsInSlash then path else path + "/";

  # List of rsync flags comes from `man rsync` (search for the `--archive`
  # docs).
  # Note: -N (--crtimes) is omitted because `rsync` on linux doesn't
  # support it? Hard to find good documentation of this, see
  # <https://github.com/RsyncProject/rsync/issues/166>.
  rsyncCmd =
    path:
    let
      pathWithSlash = ensureTrailingSlash path;
    in
    /* bash */ ''
      echo "Backing up ${lib.escapeShellArg pathWithSlash}"
      rsync \
        -aAXUHv --delete \
        --rsh="ssh -i ${keypair.privateKeyfile}" \
        ${lib.escapeShellArg pathWithSlash} ${box.user}@${box.host}:${lib.escapeShellArg pathWithSlash}
    '';

  fflewddur-backup-to-fflam = pkgs.writeShellApplication {
    name = "fflewddur-backup-to-fflam";
    runtimeInputs = [
      pkgs.curl
      pkgs.rsync
      pkgs.openssh
    ];
    text = /* bash */ ''
      start_time=$(date +%s.%N)

      ${lib.concatStringsSep "\n" (map rsyncCmd backupPaths)}

      end_time=$(date +%s.%N)
      duration_seconds=$(echo "$end_time - $start_time" | ${lib.getExe pkgs.bc})

      # Finally, report a successful backup =)
      echo "That backup took $duration_seconds seconds. Reporting success to Prometheus"
      echo 'backup_completion_timestamp_seconds{site="fflam"}' "$(date +%s)" | ${pkgs.moreutils}/bin/sponge ${config.snow.monitoring.nodeTextfileDir}/backup_completion_timestamp_seconds-fflam.prom
      echo 'backup_duration_seconds{site="fflam"}' "$duration_seconds" | ${pkgs.moreutils}/bin/sponge ${config.snow.monitoring.nodeTextfileDir}/backup_duration_seconds-fflam.prom
    '';
  };
in
{
  imports = [ flake.nixosModules.fflewddur-fflam-backup-ssh-creds ];

  programs.ssh.knownHosts."fflam.m".publicKey = flake.lib.identities.fflam;

  systemd = {
    # Offsite backups.
    timers.fflewddur-backup-to-fflam = {
      description = "fflewddur -> fflam backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "fflewddur-backup-to-fflam.service";
      };
    };
    services.fflewddur-backup-to-fflam = {
      description = "fflewddur -> fflam backup";
      enable = true;
      script = lib.getExe fflewddur-backup-to-fflam;
      unitConfig = {
        RequiresMountsFor = [ backupPaths ];
      };
    };
  };
}
