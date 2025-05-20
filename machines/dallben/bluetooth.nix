{ pkgs, ... }:
{
  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  environment.systemPackages = [ pkgs.bluez ];
}
