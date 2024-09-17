{
  imports = [
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

    (
      { self, ... }:
      {
        perSystem =
          { pkgs, flakeRoot, ... }:
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
