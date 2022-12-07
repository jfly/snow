{ config, lib, pkgs, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.users.${config.snow.user.name} = (import ../shared/home.nix {
    inherit config;
  });

  environment.systemPackages = with pkgs; [
    delta # TODO: consolidate with git configuration
    jq # TODO: ~/bin/colorscheme needs this
  ];
}
