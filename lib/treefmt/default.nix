{ flake, inputs, ... }:

{
  perSystem = { pkgs, ... }:

    let
      inherit (inputs)
        treefmt-nix
        ;

      # https://github.com/numtide/treefmt-nix?tab=readme-ov-file#configuration
      conf = {
        projectRootFile = "flake.nix";
        programs.nixpkgs-fmt.enable = true;
        programs.black.enable = true;
        programs.clang-format.enable = true;
      };

      eval = treefmt-nix.lib.evalModule pkgs conf;
    in

    {
      formatter = eval.config.build.wrapper;
      check = eval.config.build.check flake;
    };
}
