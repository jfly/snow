{ config, ... }:

{
  programs.adb.enable = true;
  users.users.${config.snow.user.name}.extraGroups = [ "adbusers" ];
}
