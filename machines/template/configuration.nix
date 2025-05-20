{ flake, ... }:

{
  imports = [
    flake.nixosModules.shared
    # flake.nixosModules.monitoring # Delete if this device will roam.
    ./hardware-configuration.nix
    ./disko.nix
  ];

  ### CHANGEME ##
  networking.hostName = "template";
  # networking.domain = "ec"; # Delete if this device will roam.
  # clan.core.networking.targetHost = "jfly@localhost:5555";
  clan.core.deployment.requireExplicitUpdate = true; # You likely want to remove this.

  # Fill in the root device. Run `lsblk --output NAME,ID-LINK,FSTYPE,SIZE,MOUNTPOINT`
  # on the remote machine to get the disk id.
  # disko.devices.disk.main.device = "/dev/disk/by-id/ata-QEMU_HARDDISK_QM00001";

  services.getty.helpLine = ''
    This is a dead simple example of a fleet member. It's used as a template
    for creating new members of the fleet.
  '';
}
