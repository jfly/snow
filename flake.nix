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
    flake-inputs@{ nixpkgs, ... }: # <<< TODO: remove unused nixpkgs variable after fixing borked lockfile >>>
    let
      flake = flake-inputs.self;
      inputs = flake-inputs // { inherit (flake.lib) agenix-rooter; };
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
      perSystem = { inputs', self', pkgs, lib, system, ... }:
        let
          flake' = self';
          systemArgs = systemlessArgs // {
            inherit inputs' flake' pkgs system;
          };
          inherit (lib)
            mapAttrs'
            nameValuePair
            filterAttrs
            ;

          lib' = mapAttrs'
            (name: lib: nameValuePair name (lib.perSystem systemArgs))
            (filterAttrs (name: lib: lib ? perSystem) flake.lib);
        in
        {
          apps = lib'.agenix-rooter.apps;
          devShells.default = flake'.packages.devShell;
          packages = lib'.packages;
          # TODO: consolidate treefmt configuration with pre-commit-hooks? See
          # https://github.com/cachix/git-hooks.nix/issues/287
          formatter = lib'.treefmt.formatter;

          checks = flake.lib.flattenTree {
            formatting = lib'.treefmt.check;
            pre-commit-check = lib'.pre-commit-hooks;
            nixos = filterAttrs
              #<<< TODO: >>> kent currently won't build due to an error
              # building the python cryptography package. Hopefully this will go
              # away when we update nixpkgs.
              (name: os: name != "kent")
              (mapAttrs'
                (name: nixosConfiguration: nameValuePair name nixosConfiguration.config.system.build.toplevel)
                flake.nixosConfigurations);
          };
        };
    });
}
