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
    ./speedtest.nix
  ];

  networking.hostName = "doli";
}
