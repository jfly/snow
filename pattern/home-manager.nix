{ config, lib, pkgs, ... }:

{
  imports = [
    (import ../sources.nix).home-manager-nixos # Set up home-manager.
  ];

  config = {
    home-manager.useGlobalPkgs = true;
    home-manager.users.${config.snow.user.name} = (import ../shared/home.nix {
      username = config.snow.user.name;
    });

    environment.systemPackages = with pkgs; [
      delta # TODO: consolidate with git configuration
    ];
  };
}
