{
  _module.args.flakeRoot = ../.;

  imports = [
    # inputs
    ./patched-nixpkgs.nix

    # outputs
    ./lib.nix
    ./packages.nix
    ./nixos-modules.nix
    ./nixos-hosts.nix

    # development
    ./formatting.nix
    ./git-hooks.nix
    ./dev-shell.nix

    # TODO: move away from agenix-rooter to agenix-rekey.
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
