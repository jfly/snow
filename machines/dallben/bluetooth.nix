{ pkgs, ... }:
{
  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  environment.systemPackages = [ pkgs.bluez ];

  snow.backup.paths = [ "/var/lib/bluetooth" ];
}
