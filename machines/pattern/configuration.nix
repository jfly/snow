{
  flake,
  inputs,
  ...
}:
{
  # TODO: >>> can we get rid of this? or at least minimize it's usage? <<<
  snow.user = {
    name = "jfly";
    uid = 1000;
  };

  imports = [
    flake.nixosModules.shared
    flake.nixosModules.laptop
    ./hardware-configuration.nix
    ./hardware-configuration-custom.nix
    ./disko.nix
    ./network.nix
    ./users.nix
    ./audio.nix
    inputs.home-manager.nixosModules.home-manager
    ./home-manager.nix
    ./sshd.nix
    ./shell
    ./desktop
    ./pim
    ./fingerprint.nix
    ./android.nix
    ./development.nix
    ./syncthing.nix
    ./printers.nix
    ./fuse.nix
    ./garage-status.nix
    ./remote-builders.nix
    ./tor.nix
    ./waydroid.nix
    ./remote-fs.nix
    ./steam.nix
    ./irc-client.nix
  ];

  # This device is not online all the time.
  snow.monitoring.alertIfDown = false;

  # We don't back up any data from this machine.
  snow.backup.enable = false;

  # <<< disko.devices.disk.main.device = "/dev/disk/by-id/nvme-SAMSUNG_MZVLB1T0HALR-000L7_S3TPNE0JB02226";

  programs.nix-ld.enable = true;
}
