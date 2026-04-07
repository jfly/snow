{ flake, ... }:

{
  imports = [
    flake.nixosModules.shared
    ./hardware-configuration.nix
    ./disko.nix
    ./tang.nix
  ];

  networking.hostName = "clark";
  disko.devices.disk.main.device = "/dev/disk/by-id/ata-DOGFISH_SSD_256GB_GV211122L000000730";
  snow.network.lan = {
    tld = "ec";
    ip = "192.168.28.110"; # Keep this in sync with <routers/strider/files/etc/config/dhcp>.
  };

  # We don't back up any data from this machine. If we lose the Tang secrets,
  # that's OK.
  snow.backup.enable = false;
}
