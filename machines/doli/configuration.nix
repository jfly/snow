{ flake, ... }:

{
  imports = [
    flake.nixosModules.shared
    flake.nixosModules.syncthing
    ./hardware-configuration.nix
    ./network.nix
    ./disko.nix
    ./mail.nix
    ./zrepl.nix
    ./vaultwarden-test.nix
  ];

  networking.hostName = "doli";
}
