{ pkgs, ... }:
{
  # Enable bluetooth
  hardware.bluetooth.enable = true;
  environment.systemPackages = [ pkgs.bluez ];
}
