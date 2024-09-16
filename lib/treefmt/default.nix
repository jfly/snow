{ inputs, ... }:

{ pkgs, ... }:

let
  inherit (inputs)
    treefmt-nix
    ;

  # https://github.com/numtide/treefmt-nix?tab=readme-ov-file#configuration
  conf = {
    projectRootFile = "flake.nix";

    programs.nixpkgs-fmt.enable = true;

    programs.black.enable = true;
    settings.formatter.black.excludes = [ "iac/pulumi/crds/*.py" ]; # >>> TOOD: remove this code in favor of a nix derivation <<<

    programs.clang-format.enable = true;
  };

in

{
  eval = treefmt-nix.lib.evalModule pkgs conf;
}
