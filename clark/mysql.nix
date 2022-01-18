{ pkgs, ... }:

# This is the owner id of the various files under /mnt/media/mysql/. I think
# this id came from however Arch Linux packaged up mariadb.
let mysql_id = 972;
in
{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    dataDir = "/mnt/media/mysql/";
  };

  ids.uids.mysql = pkgs.lib.mkOverride 0 mysql_id;
  ids.gids.mysql = pkgs.lib.mkOverride 0 mysql_id;
  users.users = {
    mysql = {
      isSystemUser = true;
    };
  };
}
