{ inputs, ... }: {
  # TODO: consolidate treefmt configuration with pre-commit-hooks? See
  # https://github.com/cachix/git-hooks.nix/issues/287
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem.treefmt = {
    projectRootFile = "flake.nix";
    programs = {
      nixpkgs-fmt.enable = true; # <<< deprecated. TODO: switch to [nixfmt-rfc-style](https://github.com/NixOS/nixfmt) >>>
      black.enable = true;
      clang-format.enable = true;
    };
  };
}
