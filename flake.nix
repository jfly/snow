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
  };

  outputs =
    flake-inputs@{ self
    , nixpkgs
    , flake-parts
    , mach-nix
    , treefmt-nix
    , ...
    }:
    let
      # TODO: extract into separate repo, or consume as a relative flake once
      # relative flake references are less painful to deal with. See
      # https://github.com/NixOS/nix/issues/3978#issuecomment-952418478
      agenix-rooter = import ./hosts/shared/agenix-rooter;
      inputs = flake-inputs // { inherit (self.lib) agenix-rooter; };
    in
    flake-parts.lib.mkFlake { inherit inputs; } ({ withSystem, ... }:
    let
      systemlessArgs = {
        flake = self;
        inherit inputs withSystem;
      };
    in
    {
      systems = [ "x86_64-linux" ];
      perSystem = { inputs', self', pkgs, system, ... }:
        let
          systemArgs = systemlessArgs // {
            inherit inputs';
            flake' = self';
          };
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
          inherit (inputs.nixpkgs.lib)
            filesystem
            ;
        in
        {
          apps = self.lib.agenix-rooter.defineApps {
            outputs = self;
            inherit pkgs;
            flakeRoot = ./.;
          };

          devShells.default = pkgs.callPackage ./shell.nix systemArgs;

          packages = filesystem.packagesFromDirectoryRecursive {
            callPackage = pkgs.newScope systemArgs;
            directory = ./pkgs;
          };

          formatter = treefmtEval.config.build.wrapper;
          checks = {
            formatting = treefmtEval.config.build.check self;
          };
        };

      flake = rec {
        nixosConfigurations = import ./hosts systemlessArgs;
        lib = import ./lib systemlessArgs;
        nixosModules = import ./modules systemlessArgs;

        hydraJobs =
          let
            inherit (nixpkgs.lib) mapAttrs' nameValuePair;
          in
          mapAttrs'
            (name: nixosConfiguration: nameValuePair "nixos-${name}" nixosConfiguration.config.system.build.toplevel)
            nixosConfigurations;
      };
    });
}
