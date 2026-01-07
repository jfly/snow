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
  keypair = {
    privateKeyfile = config.clan.core.vars.generators.fflewddur-fflam-backup-ssh.files."key".path;
  };
  box = {
    user = "root";
    host = "fflam.m";
    port = 22;
  };
  fflewddur-backup-to-fflam = pkgs.writeShellApplication {
    name = "fflewddur-backup-to-fflam";
    runtimeInputs = [
      pkgs.curl
      pkgs.rsync
      pkgs.openssh
    ];
    text =
      let
        # Note: the trailing slash here is really important for rsync to do the
        # right thing!
        backupPath = "/mnt/bay/";
      in
      ''
        start_time=$(date +%s.%N)

        # List of rsync flags comes from `man rsync` (search for the `--archive`
        # docs).
        # Note: -N (--crtimes) is ommitted because `rsync` on linux doesn't
        # support it? Hard to find good documentation of this, see
        # <https://github.com/RsyncProject/rsync/issues/166>.
        rsync \
          -aAXUHv --delete \
          --rsh="ssh -i ${keypair.privateKeyfile}" \
          ${lib.escapeShellArg backupPath} ${box.user}@${box.host}:${lib.escapeShellArg backupPath}

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

  # Generated with `ssh-keyscan fflam.m`
  programs.ssh.knownHosts."fflam.m".publicKey =
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCoA4aePxYWmpVc2xP3L2etiGfhtAbDwwx4rdqeUxjNWlA/w/vE7bQn1EWzi1WMwsBD0kFqB430H3RtxYqLbxO5a1YvgE3aQzpRQ0c2MCFSpVWPs0+8Kx2S2rIVNbeePKAA5rH03vLJ36b3WlD1gVwqCW6ZBgYXBUJ06zvIkXAHUp6fxPUZ7U9ZKZ5S9j+b/PYv9derwScK8orV35g009pn6za1VNiPmsU4OqiwtUM/dACzJKmq/kGPRbsc+gh/n1+bAXALjCid8ne3ppF5njb2AYCIwli1nw/Vg2MQaIIn+Dq1h8tMne3QQG48H6YeZfrIl/hZkwWuwh6VpSLIeJq2JazPp80LxEIjLHqF0f3CLgn/1IGEamzFgiSYSbrBCY0L33UYVKvTGpUDbipKMJczZ+SIy01OlfQLsz/3Oz9VLyimDKYmXtSCV+rZgfRSiE+MDpODePT92vIavb7vtZ6mnEkinrZFb77OsoW1YRsfI8bb06W9AhFjSwJxv6I38ratwvnRG2/jA+kfHdI2bjfLrMHcdq0pa38y48xVoSIhP6LOTh00Mpvx9h7uMQqq7MrGxs939r/uX9awGghgwsfw85nTsNI3coi9lSWxujzcTd6tT0+zX0XAj1gvPkjKAfnyIBBVNFmeDzC+P6zMiHd8b3ZiedDKBRmzCmmYZdg9aQ==";

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
    };
  };
}
