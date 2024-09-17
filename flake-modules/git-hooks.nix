{ inputs, ... }:

{
  imports = [ inputs.git-hooks-nix.flakeModule ];

  perSystem = { self', ... }: {
    pre-commit.settings.hooks = {
      nil = {
        enable = true;
        package = self'.packages.strict-nil;
      };
    };
  };
}
