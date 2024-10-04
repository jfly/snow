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

  nixpkgs.hostPlatform = "x86_64-linux";

  # This is little more personal than "nixos".
  # The user is defined in the shared nixos module.
  services.getty.autologinUser = lib.mkForce "jfly";

  # Enable ssh.
  services.openssh.enable = true;

  # Use "full" neovim.
  snow.neovim.package = flake'.packages.neovim;

  # Allow ssh as the root user. nixos-anywhere needs this:
  # <https://github.com/nix-community/nixos-anywhere/pull/293#pullrequestreview-1962541552>
  users.users.root.openssh.authorizedKeys.keys = [ identities.jfly ];

  system.stateVersion = config.system.nixos.release;
}
