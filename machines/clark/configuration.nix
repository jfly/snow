{ flake, ... }:

{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.initrd-ssh-tor
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
}
