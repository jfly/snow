{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks-nix.flakeModule
  ];

  perSystem.pre-commit.settings.hooks.treefmt.enable = true;

  perSystem.treefmt = {
    projectRootFile = "flake.nix";
    programs = {
      # Formatters
      nixfmt.enable = true;
      black.enable = true;
      clang-format.enable = true;
      fish_indent.enable = true;
      ormolu.enable = true;
      # Linters
      nixf-diagnose.enable = true;
    };
  };
}
