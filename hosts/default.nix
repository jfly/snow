{ flake, inputs, withSystem, ... }:

let
  inherit (inputs.nixpkgs.lib)
    filterAttrs
    mapAttrs
    ;

  evalConfig = let ogEvalConfig = import "${inputs.nixpkgs}/nixos/lib/eval-config.nix"; in { name }: ogEvalConfig {
    # (copied from https://github.com/NixOS/nixpkgs/blob/9de34b26321950ad1ea29c6d12ad5adf01b0dc3b/flake.nix#L27-L30)
    # Allow system to be set modularly in nixpkgs.system.
    # We set it to null, to remove the "legacy" entrypoint's
    # non-hermetic default.
    system = null;

    specialArgs = {
      inherit inputs flake;
    };

    modules = [
      flake.nixosModules.shared
      (./. + "/${name}/configuration.nix")
      ({ pkgs, ... }: {
        _module.args = {
          inputs' = withSystem pkgs.system ({ inputs', ... }: inputs');
          flake' = withSystem pkgs.system ({ self', ... }: self');
        };
      })
    ];
  };

  hostDirs = filterAttrs (_name: type: type == "directory") (builtins.readDir ./.);
in

mapAttrs (name: _type: evalConfig { inherit name; }) hostDirs
