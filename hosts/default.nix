{ self, inputs, ... }:

let
  inherit (inputs.nixpkgs.lib)
    filterAttrs
    mapAttrs
    ;
  nixpkgs = import inputs.nixpkgs {
    # TODO: figure out if this is possible to achieve without being specific
    # about `system`.
    system = "x86_64-linux";
  };
  inherit (nixpkgs)
    fetchpatch
    applyPatches;

  patchedNixpkgs = applyPatches {
    name = "nixos-unstable-patched";
    src = inputs.nixos-unstable;
    patches = [
      (fetchpatch {
        name = "latest inkscape/silhouette unstable";
        url = "https://github.com/jfly/nixpkgs/commit/653dd896a6cb28f2bc206dc8566348e649bea7d4.patch";
        hash = "sha256-/NJqA1zYJ+uYMQ3tV9zyUG6n4LqeIjcyvvfSr07BVps=";
      })
      # https://github.com/NixOS/nixpkgs/pull/326142
      (fetchpatch {
        name = "fix wxPython on Python 3.12";
        url = "https://github.com/NixOS/nixpkgs/compare/master...jfly:nixpkgs:wxpython-fix.patch";
        hash = "sha256-Nv+Di7GNJFSGAclNNCgbDCluPOyDcd7m6jLI2NLRGu8=";
      })
    ];
  };

  evalConfig = let ogEvalConfig = import "${patchedNixpkgs}/nixos/lib/eval-config.nix"; in { name }: ogEvalConfig {
    # (copied from https://github.com/NixOS/nixpkgs/blob/9de34b26321950ad1ea29c6d12ad5adf01b0dc3b/flake.nix#L27-L30)
    # Allow system to be set modularly in nixpkgs.system.
    # We set it to null, to remove the "legacy" entrypoint's
    # non-hermetic default.
    system = null;

    specialArgs = {
      inherit inputs;
      flake = self;
    };

    modules = [
      self.nixosModules.shared
      (./. + "/${name}/configuration.nix")
    ];
  };

  hostDirs = filterAttrs (_name: type: type == "directory") (builtins.readDir ./.);
in

mapAttrs (name: _type: evalConfig { inherit name; }) hostDirs
