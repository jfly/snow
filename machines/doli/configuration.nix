{ flake, ... }:

{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.syncthing
    ./hardware-configuration.nix
    ./network.nix
    ./disko.nix
    ./mail.nix
  ];

  # https://wiki.nixos.org/wiki/Install_NixOS_on_Hetzner_Cloud#Network_configuration
  boot.loader.grub.enable = true;

  networking.hostName = "doli";
}
