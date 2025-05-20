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

    # TODO: move away from `agenix-rooter` to `agenix-rekey`.
    (
      { self, flakeRoot, ... }:
      {
        perSystem =
          { pkgs, ... }:
          {
            apps = self.lib.agenix-rooter.defineApps {
              flake = self;
              inherit pkgs flakeRoot;
            };
          };
      }
    )
  ];
}
