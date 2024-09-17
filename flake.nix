{
  description = "snow";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "path:/home/jeremy/src/github.com/NixOS/nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";
    poetry2nix.url = "github:nix-community/poetry2nix";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      # Choose not to download darwin deps (saves some resources on Linux, see
      # https://github.com/ryantm/agenix#install-module-via-flakes).
      inputs.darwin.follows = "";
    };

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    pr-tracker.url = "github:molybdenumsoftware/pr-tracker";
    pr-tracker.inputs.nixpkgs.follows = "nixpkgs";

    shtuff.url = "github:jfly/shtuff";
    shtuff.inputs.nixpkgs.follows = "nixpkgs";

    with-alacritty.url = "github:FatBoyXPC/with-alacritty";
    with-alacritty.inputs.nixpkgs.follows = "nixpkgs";

    on-air = {
      url = "github:jfly/on-air";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openwrt-imagebuilder.url = "github:jfly/nix-openwrt-imagebuilder/update-hashes";
    # openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";

    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    raw-inputs:
    let
      flake = raw-inputs.self;
      nixpkgs = import raw-inputs.nixpkgs { system = "x86_64-linux"; };
      inherit (nixpkgs)
        fetchpatch
        applyPatches;

      patchedNixpkgs = applyPatches {
        name = "nixpkgs-patched";
        src = raw-inputs.nixpkgs;
        patches = [
          (fetchpatch {
            name = "latest inkscape/silhouette unstable";
            url = "https://github.com/jfly/nixpkgs/commit/653dd896a6cb28f2bc206dc8566348e649bea7d4.patch";
            hash = "sha256-/NJqA1zYJ+uYMQ3tV9zyUG6n4LqeIjcyvvfSr07BVps=";
          })
          (fetchpatch {
            name = "crd2pulumi: 1.4.0 -> 1.5.0";
            url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/341701.patch";
            hash = "sha256-6WQPB2+Y0NTP2D9aCOEOG7VTuHVW3443JJ8RnqjveNA=";
          })
        ];
      };
      inputs = raw-inputs // { inherit (flake.lib) agenix-rooter; };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ withSystem, ... }:
    let
      systemlessArgs = {
        flakeRoot = ./.;
        inherit inputs withSystem flake;
      };
    in
    {
      flake = {
        nixosConfigurations = import ./hosts systemlessArgs;
        lib = import ./lib systemlessArgs;
        nixosModules = import ./modules systemlessArgs;
      };

      systems = [ "x86_64-linux" ];
      perSystem = { inputs', self', lib, system, ... }:
        let
          lib' = mapAttrs'
            (name: lib: nameValuePair name (lib.perSystem systemArgs))
            (filterAttrs (name: lib: lib ? perSystem) flake.lib);
          flake' = self' // { lib = lib'; };
          pkgs = import patchedNixpkgs { inherit system; };
          systemArgs = systemlessArgs // {
            inherit inputs' flake' pkgs system;
          };
          inherit (lib)
            mapAttrs'
            nameValuePair
            filterAttrs
            ;

        in
        {
          apps = flake'.lib.agenix-rooter.apps;
          devShells.default = flake'.packages.devShell;
          packages = flake'.lib.packages;
          # TODO: consolidate treefmt configuration with pre-commit-hooks? See
          # https://github.com/cachix/git-hooks.nix/issues/287
          formatter = lib'.treefmt.formatter;

          checks = flake.lib.flattenTree {
            formatting = flake'.lib.treefmt.check;
            pre-commit-check = flake'.lib.pre-commit-hooks;
            nixos = mapAttrs'
              (name: nixosConfiguration: nameValuePair name nixosConfiguration.config.system.build.toplevel)
              flake.nixosConfigurations;
          };
        };
    });
}
