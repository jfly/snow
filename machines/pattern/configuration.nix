{
  flake,
  inputs,
  ...
}:
{
  snow.user = {
    name = "jeremy";
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

  programs.nix-ld.enable = true;
}
