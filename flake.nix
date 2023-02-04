{
  description = "snow";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";

    mach-nix.url = "github:DavHau/mach-nix";
    mach-nix.inputs.flake-utils.follows = "flake-utils";

    # Note: colmena comes with nixpkgs, but we need a version with
    # https://github.com/zhaofengli/colmena/commit/ca12be27edf5639fa3c9c98d6b4ab6d1f22e3315
    # so `deage.file`'s impurity works when doing an apply-local.
    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.flake-utils.follows = "flake-utils";

    # TODO unpin nixos-unstable. We're pinned to an older version for the following reasons:
    #  - vagrant won't build. fixed by: https://nixpk.gs/pr-tracker.html?pr=211323
    #  - kodi won't build. fixed by: https://nixpk.gs/pr-tracker.html?pr=210941
    #  - mycli won't build. not yet fixed, tracked here: https://github.com/NixOS/nixpkgs/issues/211415
    nixos-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    parsec-gaming.url = "github:DarthPJB/parsec-gaming-nix";
    parsec-gaming.inputs.nixpkgs.follows = "nixpkgs";

    # TODO: unpin home-manager one we've on the latest nixos-unstable again.
    # Until we get there, the home-manager manual won't build: https://github.com/nix-community/home-manager/issues/3344
    home-manager.url = "github:nix-community/home-manager/7d55a72d4c1df694e87a41a7e6c9a7b6e9a40ca3";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # This used to be accessible at BentonEdmondson/knock, but that repo has
    # disappeared. After some crawling through archive.org, I found an up to
    # date fork, and forked it myself. I've also emailed the maintainer, but haven't heard back from him.
    # More places to look for information:
    #  - https://superuser.com/a/1664172/1765828
    #  - https://aur.archlinux.org/packages/knock-bin
    # If this repo is unmaintained, consider maintaining it yourself or maybe
    # switching to [Libgourou](https://indefero.soutade.fr/p/libgourou/)
    knock.url = "github:jfly/knock";
    knock.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , knock
    , mach-nix
    , colmena
    , nixos-unstable
    , parsec-gaming
    , home-manager
    }:
    (
      flake-utils.lib.eachDefaultSystem
        (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = import ./overlays;
          };
        in
        {
          devShells.default = pkgs.callPackage ./shell.nix {
            mach-nix = mach-nix.lib."${system}";
            colmena = colmena.defaultPackage."${system}";
          };
        }
        )
    ) // {

      colmena = {
        meta = {
          nixpkgs = import nixos-unstable {
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
                  }
              )
            ];
          };

          # Colmena doesn't require it, but put every single host in here. I'd prefer
          # to *not* have a fallback value defined for nixpkgs at all.
          # https://github.com/zhaofengli/colmena/issues/54 tracks that feature
          # request for Colmena.
          nodeNixpkgs = rec {
            clark = import nixos-unstable {
              overlays = import ./overlays;
            };
            dallben = import nixos-unstable {
              overlays = import ./overlays;
            };
            fflewddur = import nixos-unstable {
              overlays = import ./overlays;
            };
            fflam = import nixos-unstable {
              overlays = import ./overlays;
            };
            pattern = import nixos-unstable {
              overlays = import ./overlays;
            };
          };
        };

        # This configuration applies to *every* node in the hive.
        defaults = { pkgs, ... }: {
          environment.systemPackages = with pkgs; [
            vim
            wget
            curl
            mosh
            tmux
          ];

          environment.variables = {
            EDITOR = "vim";
          };

          users.groups.media = { gid = 1002; };

          # Ensure that commands like `nix repl` and `nix-shell` have access to the
          # same nixpkgs we use to install everything else.
          nix.nixPath = [ "nixpkgs=${pkgs.path}" ];
        };

        "clark" = import clark/configuration.nix;
        "dallben" = import dallben/configuration.nix { inherit parsec-gaming; };
        "fflewddur" = import fflewddur/configuration.nix;
        "fflam" = import fflam/configuration.nix;
        "pattern" = import pattern/configuration.nix {
          inherit parsec-gaming home-manager;
          knock-flake = knock;
        };
      };
    };
}
