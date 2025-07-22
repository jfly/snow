{ pkgs, ... }:

{
  snow.backup = {
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

    paths = [ "/state" ];
    exclude = [
      # This is a symlink into `/nix/store`
      "/state/postgresql/postgresql.conf"
    ];
  };
}
