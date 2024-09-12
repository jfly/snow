{
  description = "snow";

  inputs = {
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixos-unstable.url = "path:/home/jeremy/src/github.com/NixOS/nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    # TODO: switch to poetry2nix
    pypi-deps-db.url = "github:DavHau/pypi-deps-db";
    mach-nix.url = "github:DavHau/mach-nix";
    # Can't use the latest nixpkgs because of https://github.com/DavHau/mach-nix/issues/524
    # mach-nix.inputs.nixpkgs.follows = "nixpkgs";
    mach-nix.inputs.pypi-deps-db.follows = "pypi-deps-db";

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      # Choose not to download darwin deps (saves some resources on Linux, see
      # https://github.com/ryantm/agenix#install-module-via-flakes).
      inputs.darwin.follows = "";
    };

    # TODO: get rid of colmena in favor of `nixos-rebuild --flake ...`
    # Note: colmena comes with nixpkgs, but we need a version with
    # https://github.com/zhaofengli/colmena/commit/ca12be27edf5639fa3c9c98d6b4ab6d1f22e3315
    # so `deage.file`'s impurity works when doing an apply-local.
    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";

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
  };

  outputs =
    flake-inputs@{ self
    , nixpkgs
    , flake-parts
    , mach-nix
    , colmena
    , treefmt-nix
    , shtuff
    , with-alacritty
    , on-air
    , ...
    }:
    let
      # TODO: extract into separate repo, or consume as a relative flake once
      # relative flake references are less painful to deal with. See
      # https://github.com/NixOS/nix/issues/3978#issuecomment-952418478
      agenix-rooter = import ./hosts/shared/agenix-rooter;
      inputs = flake-inputs // { inherit (self.lib) agenix-rooter; };

      overlays = [
        (import ./overlay.nix { inherit inputs; })
      ];
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem = { inputs', self', system, ... }:
        let
          pkgs = import nixpkgs {
            inherit system overlays;
          };
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        in
        {
          apps = self.lib.agenix-rooter.defineApps {
            outputs = self;
            inherit pkgs;
            flakeRoot = ./.;
          };

          devShells.default = pkgs.callPackage ./shell.nix {
            mach-nix = mach-nix.lib."${system}";
            colmena = colmena.defaultPackage."${system}".overrideAttrs (oldAttrs: {
              patches = [
                # This is a workaround for https://github.com/NixOS/nix/issues/6950
                ./colmena-ssh-speedup.patch
              ];
            });
          };

          formatter = treefmtEval.config.build.wrapper;
          checks = {
            formatting = treefmtEval.config.build.check self;
          };
        };

      flake = rec {
        colmenaHive = import ./hosts { inherit self inputs overlays; };
        nixosConfigurations = colmenaHive.nodes;

        lib = import ./lib {};
        nixosModules = import ./modules {};

        hydraJobs =
          let
            inherit (nixpkgs.lib) mapAttrs' nameValuePair;
          in
          mapAttrs'
            (name: nixosConfiguration: nameValuePair "nixos-${name}" nixosConfiguration.config.system.build.toplevel)
            nixosConfigurations;
      };
    };
}
