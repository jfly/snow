{
  description = "snow";

  inputs = {
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixos-unstable.url = "github:jfly/nixpkgs/jfly/nixos-unstable";
    # nixos-unstable.url = "path:/home/jeremy/src/github.com/NixOS/nixpkgs";

    systems.url = "github:nix-systems/x86_64-linux";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";

    pypi-deps-db.url = "github:DavHau/pypi-deps-db";
    mach-nix.url = "github:DavHau/mach-nix";
    mach-nix.inputs.flake-utils.follows = "flake-utils";
    # Can't use the latest nixpkgs because of https://github.com/DavHau/mach-nix/issues/524
    # mach-nix.inputs.nixpkgs.follows = "nixpkgs";
    mach-nix.inputs.pypi-deps-db.follows = "pypi-deps-db";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.home-manager.follows = "home-manager";
    # Choose not to download darwin deps (saves some resources on Linux, see
    # https://github.com/ryantm/agenix#install-module-via-flakes).
    agenix.inputs.darwin.follows = "";

    # TODO: extract into separate repo, or re-add once relative flake
    # references are less painful to deal with. See
    # https://github.com/NixOS/nix/issues/3978#issuecomment-952418478
    # agenix-rooter.url = "path:./shared/agenix-rooter";
    # agenix-rooter.inputs.nixpkgs.follows = "nixpkgs";

    # Note: colmena comes with nixpkgs, but we need a version with
    # https://github.com/zhaofengli/colmena/commit/ca12be27edf5639fa3c9c98d6b4ab6d1f22e3315
    # so `deage.file`'s impurity works when doing an apply-local.
    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.flake-utils.follows = "flake-utils";
    colmena.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

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
    { self
    , nixpkgs
    , flake-utils
    , mach-nix
    , pypi-deps-db
    , colmena
    , nixos-unstable
    , home-manager
    , agenix
    , treefmt-nix
    , nixos-hardware
    , pr-tracker
    , shtuff
    , with-alacritty
    , on-air
    , ...
    }:
    let
      agenix-rooter = import ./shared/agenix-rooter { inherit nixpkgs; };

      patchNixpkgs = { nixpkgs, genPatches }:
        let
          patched = nixpkgs.applyPatches
            {
              name = "nixos-unstable-patched";
              src = nixpkgs.path;
              patches = genPatches nixpkgs;
            };
        in
        import patched {
          inherit (nixpkgs) system overlays;
        };
    in
    (
      flake-utils.lib.eachDefaultSystem
        (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = import ./overlays { inherit with-alacritty; };
          };
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        in
        {
          apps = agenix-rooter.defineApps {
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
        }
        )
    ) // rec {
      colmenaHive = colmena.lib.makeHive {
        meta = {
          nixpkgs = import nixos-unstable {
            system = "x86_64-linux";

            overlays = [
              (
                self: super:
                  let lib = super.lib;
                  in
                  {
                    # This overlay lets us convert a given colmena node into
                    # something that could get loaded on a usb drive and become a
                    # "portable" environment.
                    # See the call to `colmena eval` in `tools/build-portable-usb.sh`
                    # to see how this is used.
                    toLiveUsb = { node, encryptedRootDevice, decryptedRootDevice, bootDevice }: node.extendModules {
                      modules = [
                        {
                          boot = {
                            loader = {
                              efi.canTouchEfiVariables = lib.mkForce true;
                              grub.efiInstallAsRemovable = true;
                            };
                          };

                          fileSystems."/" = {
                            device = lib.mkForce decryptedRootDevice;
                          };
                          boot.initrd.luks.devices."cryptroot".device = lib.mkForce encryptedRootDevice;
                          fileSystems."/boot".device = lib.mkForce bootDevice;
                        }
                      ];
                    };

                    toRpiSdCard = { node, pkgs }: node.extendModules {
                      modules = [
                        # Despite the name, I don't think sd-image-raspberrypi
                        # is the right thing to use. It *appears* to be
                        # deprecated?
                        # "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-raspberrypi.nix"
                        "${pkgs.path}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
                      ];
                    };
                  }
              )
            ];
          };

          # Colmena doesn't require it, but put every single host in here. I'd prefer
          # to *not* have a fallback value defined for nixpkgs at all.
          # https://github.com/zhaofengli/colmena/issues/54 tracks that feature
          # request for Colmena.
          nodeNixpkgs = rec {
            clark = patchNixpkgs {
              nixpkgs = import nixos-unstable {
                system = "x86_64-linux";
                overlays = import ./overlays { inherit with-alacritty; };
              };
              genPatches = unpatched: [ ];
            };
            dallben = import nixos-unstable {
              system = "x86_64-linux";
              overlays = import ./overlays { inherit with-alacritty; };
            };
            fflewddur = import nixos-unstable {
              system = "x86_64-linux";
              overlays = import ./overlays { inherit with-alacritty; };
            };
            kent = import nixos-unstable {
              system = "x86_64-linux";
              overlays = import ./overlays { inherit with-alacritty; };
            };
            pattern = patchNixpkgs {
              nixpkgs = (import nixos-unstable {
                system = "x86_64-linux";
                overlays = import ./overlays { inherit with-alacritty; };
              });
              genPatches = unpatched: [
                (unpatched.fetchpatch {
                  name = "latest inkscape/silhouette unstable";
                  url = "https://github.com/jfly/nixpkgs/commit/653dd896a6cb28f2bc206dc8566348e649bea7d4.patch";
                  hash = "sha256-/NJqA1zYJ+uYMQ3tV9zyUG6n4LqeIjcyvvfSr07BVps=";
                })
              ];
            };
          };
        };

        defaults = { pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            vim
            wget
            curl
            tmux
          ];

          programs.mosh.enable = true;

          environment.variables = {
            EDITOR = "vim";
          };

          users.groups.media = { gid = 1002; };

          # Ensure that commands like `nix repl` and `nix-shell` have access to the
          # same nixpkgs we use to install everything else.
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
        };

        "clark" = import clark/configuration.nix {
          inherit agenix agenix-rooter pr-tracker;
        };
        "dallben" = import dallben/configuration.nix {
          inherit agenix agenix-rooter;
        };
        "fflewddur" = import fflewddur/configuration.nix {
          inherit agenix agenix-rooter;
        };
        "pattern" = import pattern/configuration.nix {
          inherit agenix agenix-rooter home-manager on-air shtuff with-alacritty;
        };
        "kent" = import kent/configuration.nix {
          inherit agenix agenix-rooter;
        };
      };

      nixosConfigurations = colmenaHive.nodes;

      hydraJobs =
        let
          inherit (nixpkgs) lib;
        in
        lib.mapAttrs'
          (name: nixosConfiguration:
            lib.nameValuePair
              "nixos-${name}"
              (
                let
                  finalSystem = (if name == "pattern" then
                    nixosConfiguration.extendModules
                      {
                        modules = [
                          ({ config, pkgs, lib, ... }: {
                            # Disable building the honor cli in CI: it requires
                            # access to a private repo that I only have access
                            # to from my laptop.
                            snow.enable-h4 = false;
                          })
                        ];
                      } else nixosConfiguration);
                in
                finalSystem.config.system.build.toplevel
              )
          )
          nixosConfigurations;
    };
}
