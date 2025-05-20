{
  description = "snow";

  nixConfig = {
    abort-on-warn = true;
  };

  inputs = {
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        # Choose not to download darwin dependencies (saves some resources on Linux, see
        # https://github.com/ryantm/agenix#install-module-via-flakes).
        darwin.follows = "";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
      };
    };

    clan-core = {
      # For hacking.
      # url = "path:/home/jeremy/src/git.clan.lol/clan/clan-core";

      # TODO: this doesn't work when pattern is deploying to itself? (perhaps only when copying/bootstrapping secrets?) >>>
      # https://git.clan.lol/clan/clan-core/issues/3556
      # url = "https://git.clan.lol/jfly/clan-core/archive/local-update.tar.gz";

      # TODO: switch back to upstream once the above issues are resolved.
      # Note: we're using `https://...tar.gz` urls here instead of git as a
      # workaround for <https://git.clan.lol/clan/clan-core/issues/3555>.
      # url = "https://git.clan.lol/clan/clan-core/archive/main.tar.gz";

      # TODO: switch back to vanilla git once above issues are resolved.
      url = "git+https://git.clan.lol/clan/clan-core";

      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    on-air = {
      url = "github:jfly/on-air";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openwrt-imagebuilder = {
      url = "github:astro/nix-openwrt-imagebuilder";
      # url = "github:jfly/nix-openwrt-imagebuilder/update-hashes";
    };

    poetry2nix.url = "github:nix-community/poetry2nix";

    git-hooks-nix.url = "github:cachix/git-hooks.nix";

    pr-tracker = {
      url = "github:molybdenumsoftware/pr-tracker";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shtuff = {
      url = "github:jfly/shtuff";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # TODO: switch back to upstream when/if
    # https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/merge_requests/344/
    # is merged.
    # simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
    simple-nixos-mailserver.url = "gitlab:jflysohigh/nixos-mailserver/dkim-path";

    systems.url = "github:nix-systems/x86_64-linux";

    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };

    with-alacritty = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:FatBoyXPC/with-alacritty";
    };
  };

  outputs =
    raw-inputs:
    let
      unpatchedPkgs = import raw-inputs.nixpkgs {
        system = "x86_64-linux";
      };
      inherit (unpatchedPkgs)
        applyPatches
        fetchpatch
        ;

      patchNixpkgs =
        {
          name,
          src,
          patches,
        }:
        let
          patchedSrc = applyPatches {
            inherit name src patches;
          };
          flake = import (patchedSrc + "/flake.nix");

          outputs = patchedSrc // (flake.outputs { self = outputs; });
        in
        outputs;

      flake = raw-inputs.self;
      inputs = raw-inputs // {
        inherit (flake.lib) agenix-rooter;

        nixpkgs = patchNixpkgs {
          name = "nixpkgs-patched";
          src = raw-inputs.nixpkgs;
          patches = [
            # To pull in https://github.com/fish-shell/fish-shell/commit/4ce552bf949a8d09c483bb4da350cfe1e69e3e48
            (fetchpatch {
              name = "fish: 4.0.2 -> 4.1.0-unstable";
              url = "https://github.com/NixOS/nixpkgs/compare/master...jfly:nixpkgs:fish-4.1.0-unstable.diff";
              hash = "sha256-ROfdjyjPmGP7L2uxldeyB6TVUul4IiBxyDz30t+LqFQ=";
            })
            (fetchpatch {
              name = "k3s: use patched util-linuxMinimal";
              url = "https://github.com/NixOS/nixpkgs/pull/407810.diff";
              hash = "sha256-N8tzwSZB9d4Htvimy00+Jcw8TKRCeV8PJWp80x+VtSk=";
            })
            (fetchpatch {
              name = "nixos/direnv: fix silent option... again";
              url = "https://github.com/NixOS/nixpkgs/pull/402399.diff";
              hash = "sha256-cn3t99Oa7X1dZtEyOOF1QxnP2dZUpyKL4ujoCjRSPL8=";
            })
          ];
        };
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ ./flake-modules ];
    };
}
