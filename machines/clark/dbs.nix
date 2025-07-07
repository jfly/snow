{ lib, pkgs, ... }:

# This is the owner id of the various files under `/mnt/media/mysql/`. I think
# this id came from however Arch Linux packaged up MariaDB.
let
  mysql_id = 972;
in
{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    dataDir = "/state/mysql";
  };

  ids.uids.mysql = lib.mkOverride 0 mysql_id;
  ids.gids.mysql = lib.mkOverride 0 mysql_id;
  users.users = {
    mysql = {
      isSystemUser = true;
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;
    dataDir = "/state/postgresql";
    enableTCPIP = true;
    authentication = lib.mkOverride 10 ''
      local all all trust
      host all all ::1/128 md5
      host all all 0.0.0.0/0 md5
    '';
  };
}
