{ inputs, ... }:
{
  # TODO: consolidate treefmt configuration with pre-commit-hooks? See
  # https://github.com/cachix/git-hooks.nix/issues/287
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem.treefmt = {
    projectRootFile = "flake.nix";
    programs = {
      nixfmt-rfc-style.enable = true;
      black.enable = true;
      clang-format.enable = true;
    };
  };
}
