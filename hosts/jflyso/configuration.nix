{
  lib,
  flake',
  flake,
  ...
}:

{
  imports = [
    flake.nixosModules.shared
    ./livecd.nix
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
}
