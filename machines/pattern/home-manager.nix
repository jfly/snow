{
  flake,
  config,
  pkgs,
  ...
}:

{
  home-manager.useGlobalPkgs = true;
  home-manager.users.${config.snow.user.name} = (
    import ./home.nix {
      inherit flake config;
    }
  );

  environment.systemPackages = with pkgs; [
    delta # TODO: consolidate with git configuration
    difftastic # TODO: consolidate with git configuration
  ];
}
