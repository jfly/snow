{ config, pkgs, ... }:

{
  programs.adb.enable = true;
  users.users.${config.snow.user.name}.extraGroups = [ "adbusers" ];

  environment.systemPackages = with pkgs; [
    scrcpy
  ];
}
