{ config, pkgs, ... }:

{
  age.secrets.restic-password = {
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBjN3M4bnZFbzI0Z3FpanE4
      TnNTcXZ4ak8yd0wwRCtTanNyZm9OSGFJRXc4ClFZNWQ3aTgzeG9NbzN5MkRLTUJN
      UUpJNjBqQlg0eWVhakFvWnF3dytzY0kKLS0tIC9wMGp1YVRNeEpPSldCTWowdXVh
      QXZlbnp5dlNybnNkTHJwOTk4ZXdDVGcKS4cR59+RVUhod5+R3aNNVBdoBLLvL5Yk
      V3Y26qcufEV7G+v7P1aN8NuJ/QsqRuIHHkJj
      -----END AGE ENCRYPTED FILE-----
    '';
  };
  age.secrets.backup-monitor-api-key = {
    rooterEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBsSVpzVzdPblNmWkM3TWdq
      MnB6MTZFalRQZ2pSSUhtMk1GR2RERGQwdW5JCk9acjVRSTJpSTdtQjhNOUdSa2tn
      UEJINDZyZkp3U0dkeEp1aitlM3daYkkKLS0tICtRNmNzYkNnOENHUlJUQXVMRHBt
      bjZ4T2VnK1BFamhMVEo0Q3VRelhPajgKHeURvOoU4DyYjHLknN5bHmwWg7DzRlDE
      c3xp6XFvhTJGXO7BZu5fEClY
      -----END AGE ENCRYPTED FILE-----
    '';
  };

  services.restic.backups = {
    clark-state = {
      # First, do some special handling of anything like a database that needs a
      # transactionally consistent view of the world.
      # TODO: this doesn't handle our various mysql and postgresql dbs. Rather
      # than have this grow to support all of those, figure out a more
      # distributed way of handling this. Some ideas:
      #  - Do this in a k8s cron job for each thing that needs it.
      #  - Switch to some crazy filesystem that does have support for atomic
      #    backups
      #    (https://www.reddit.com/r/sysadmin/comments/7fyn74/lvm_btrfs_zfs_what_is_the_best_solution_for/)
      backupPrepareCommand = ''
        echo "Building /state/transactionally-consistent"
        mkdir -p /state/transactionally-consistent
        ${pkgs.sqlite}/bin/sqlite3 /state/vaultwarden/db.sqlite3 ".backup '/state/transactionally-consistent/vaultwarden.sqlite'"
      '';
      # Report success!
      backupCleanupCommand = ''
        echo "Reporing success to monitoring.snow.jflei.com"
        ${pkgs.curl}/bin/curl --no-progress-meter "https://monitoring.snow.jflei.com/api/push/$(cat ${config.age.secrets.backup-monitor-api-key.path})?status=up&msg=OK&ping="
      '';

      passwordFile = config.age.secrets.restic-password.path;
      paths = [ "/state" ];
      repository = "rest:http://fflewddur:8000/";
      timerConfig = {
        OnCalendar = "daily";
      };
    };
  };
}
