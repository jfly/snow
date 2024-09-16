{ inputs, ... }:

{
  perSystem = { system, flake', ... }:

    let
      inherit (inputs)
        pre-commit-hooks;

      # https://devenv.sh/reference/options/#pre-commit
      hooks = {
        nil = {
          enable = true;
          package = flake'.packages.strict-nil;
        };
      };
    in
    pre-commit-hooks.lib.${system}.run {
      src = ../../.;
      inherit hooks;
    };
}
