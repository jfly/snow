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
  };

  outputs = { self, nixpkgs, flake-utils, mach-nix, colmena }:
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
      ) // {

      colmena = {
        meta = {
          nixpkgs = (import ./sources.nix).nixos-unstable {
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
            clark = (import ./sources.nix).nixos-unstable {
              overlays = import ./overlays;
            };
            dallben = (import ./sources.nix).nixos-unstable {
              overlays = import ./overlays;
            };
            fflewddur = (import ./sources.nix).nixos-21_11 {
              overlays = import ./overlays;
            };
            fflam = (import ./sources.nix).nixos-21_11 {
              overlays = import ./overlays;
            };
            pattern = (import ./sources.nix).nixos-unstable {
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
        "dallben" = import dallben/configuration.nix;
        "fflewddur" = import fflewddur/configuration.nix;
        "fflam" = import fflam/configuration.nix;
        "pattern" = import pattern/configuration.nix;
      };
    };
}
