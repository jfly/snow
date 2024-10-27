{
  _module.args.flakeRoot = ../.;

  imports = [
    # Inputs
    ./patched-nixpkgs.nix

    # Outputs
    ./lib.nix
    ./packages.nix
    ./containers.nix
    ./routers.nix
    ./nixos-modules.nix
    ./nixos-hosts.nix

    # Development
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
