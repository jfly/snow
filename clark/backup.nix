{ pkgs, ... }:

let
  state-backup = pkgs.writeShellApplication {
    name = "state-backup";
    runtimeInputs = with pkgs; [ findutils gnutar ];
    text = ''
      # Ensure these files are read + writeable by group.
      umask 002

      # First, do some special handling of anything like a database that needs a
      # transactionally consistent view of the world.
      # TODO: this doesn't handle our various mysql and postgresql dbs. Rather
      # than have this grow to support all of those, figure out a more
      # distributed way of handling this. Some ideas:
      #  - Do this in a k8s cron job for each thing that needs it.
      #  - Switch to some crazy filesystem that does have support for atomic
      #    backups
      #    (https://www.reddit.com/r/sysadmin/comments/7fyn74/lvm_btrfs_zfs_what_is_the_best_solution_for/)
      mkdir -p /state/transactionally-consistent
      ${pkgs.sqlite}/bin/sqlite3 /state/vaultwarden/db.sqlite3 ".backup '/state/transactionally-consistent/vaultwarden.sqlite'"

      # Create a backup with today's date
      backup=/mnt/media/backups/automated/clark-state-$(date -I).tar
      wip_backup=$backup.wip
      tar cfp "$wip_backup" /state
      mv "$wip_backup" "$backup"

      # Remove automated backups more than 10 days old
      find /mnt/media/backups/automated -type f -mtime +10 -delete
    '';
  };
in
{
  # Do a daily backup of /state
  systemd = {
    timers.state-backup = {
      description = "/state backup timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Unit = "state-backup.service";
      };
    };
    services.state-backup = {
      description = "/state backup";
      enable = true;
      script = "${state-backup}/bin/state-backup";
    };
  };
}
