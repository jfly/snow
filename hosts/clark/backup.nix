{ flake, pkgs, ... }:

{
  imports = [ flake.nixosModules.backup ];

  snow.backup = {
    enable = true;

    resticPasswordEncrypted = ''
      -----BEGIN AGE ENCRYPTED FILE-----
      YWdlLWVuY3J5cHRpb24ub3JnL3YxCi0+IFgyNTUxOSBuTll2dHZadE91bUplZE1J
      Qkl5clQ3eitDWGtUcSt2WU9uS3dpcmdoZXdZCkc5aEw3bkpQdm1MWFl3bldlSTEv
      RnRNRUxWSzd0U0l4cXdQalRNUnFaQ00KLS0tIDV5L0RZaEZSN3VqSlEyOUdkdmFM
      MDNVTFpzN2d0TzMwdWhoaHpSZWVxbjQKzMr7xrvVcjZOe2s9SIjrRG1t9J4zeQM3
      0BKKYDpUnebNlG8ckv3jL26tB+uOwRM4SiC8jQ==
      -----END AGE ENCRYPTED FILE-----
    '';

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
