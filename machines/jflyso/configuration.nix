{
  lib,
  flake',
  flake,
  config,
  ...
}:

let
  identities = flake.lib.identities;
in
{
  imports = [
    flake.nixosModules.shared
  ];

  networking.hostName = "jflyso";
  clan.core.deployment.requireExplicitUpdate = true;

  nixpkgs.hostPlatform = "x86_64-linux";

  # This is little more personal than "nixos".
  # The user is defined in the shared nixos module.
  services.getty.autologinUser = lib.mkForce "jfly";

  # Enable ssh.
  services.openssh.enable = true;

  # Use "full" neovim.
  snow.neovim.package = flake'.packages.neovim;

  # This device is not online all the time.
  snow.monitoring.alertIfDown = false;

  # Allow ssh as the root user. nixos-anywhere needs this:
  # <https://github.com/nix-community/nixos-anywhere/pull/293#pullrequestreview-1962541552>
  users.users.root.openssh.authorizedKeys.keys = [ identities.jfly ];

  system.stateVersion = config.system.nixos.release;

  # Some minimal config necessary to define a buildable machine.
  fileSystems."/".device = "/dev/null";
  boot.loader.systemd-boot.enable = true;

  # WiFi
  networking.wireless = {
    allowAuxiliaryImperativeNetworks = true;
    networks = {
      # Format:
      # "SSID".psk = "password";
    };
  };
}
