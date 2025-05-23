{
  _module.args.flakeRoot = ../.;

  imports = [
    ./lib.nix
    ./packages.nix
    ./containers.nix
    ./routers.nix
    ./nixos-modules.nix
    ./clan.nix
    ./formatting.nix
    ./git-hooks.nix
    ./dev-shell.nix
    ./check-hosts.nix
  ];
}
