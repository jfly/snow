{ config, lib, pkgs, modulesPath, ... }:
{
  # Enable bluetooth
  hardware.bluetooth.enable = true;
  environment.systemPackages = [ pkgs.bluez ];
}
