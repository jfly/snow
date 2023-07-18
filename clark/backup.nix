{ pkgs, ... }:

let
  state-backup = pkgs.writeShellScriptBin "state-backup" ''
    export PATH=$PATH:${pkgs.findutils}/bin
    export PATH=$PATH:${pkgs.gnutar}/bin

    # Ensure these files are read + writeable by group.
    umask 002

    # Create a backup with today's date
    backup=/mnt/media/backups/clark-state-$(date -I).tar
    wip_backup=$backup.wip
    tar cfp "$wip_backup" /state
    mv "$wip_backup" "$backup"

    # Remove backups more than 10 days old
    find /mnt/media/backups -type f -mtime +10 -delete
  '';
in
{
  # Do a daily backup of /state
  # TODO: also do mysqldump/pg_dump to deal with the fact that this is not
  # atomic and databases are probably finnicky.
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
