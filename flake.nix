{
  description = "snow";

  nixConfig = {
    abort-on-warn = true;
  };

  inputs = {
    clan-core = {
      url = "git+https://git.clan.lol/clan/clan-core";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-input-patcher = {
      url = "github:jfly/flake-input-patcher";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";

    git-hooks-nix.url = "github:cachix/git-hooks.nix";

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

    openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    shtuff = {
      url = "github:jfly/shtuff";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";

    systems.url = "github:nix-systems/x86_64-linux";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    with-alacritty = {
      url = "github:FatBoyXPC/with-alacritty";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    unpatchedInputs:
    let
      # Unfortunately, this utility requires hardcoding a single system. See
      # <https://github.com/jfly/flake-input-patcher?tab=readme-ov-file#known-issues>.
      patcher = unpatchedInputs.flake-input-patcher.lib.x86_64-linux;
      fetchpatch = patcher.fetchpatch;

      inputs = patcher.patch unpatchedInputs {
        nixpkgs.patches = [
          (fetchpatch {
            name = "miniflux: add options for all secret files";
            url = "https://github.com/NixOS/nixpkgs/pull/429983.diff";
            hash = "sha256-Uthu66cKkZTpNXCWyNkE/WV4topuuVwRw23Rk61/ilc=";
          })
        ];

        openwrt-imagebuilder.patches = [
          (fetchpatch {
            name = "Add an `extraPackages` parameter for easier custom packages";
            url = "https://github.com/astro/nix-openwrt-imagebuilder/pull/58.diff";
            hash = "sha256-E3HQCl7ptlv8E4XFpV8Jx9150wL05nQPAXHR6ZNY4c0=";
          })
          # (fetchpatch {
          #   name = "update hashes";
          #   url = "https://github.com/astro/nix-openwrt-imagebuilder/compare/main...jfly:nix-openwrt-imagebuilder:update-hashes.diff";
          #   hash = "sha256-T1NFROM7j56DI1QjTBQX3icly04sUEtwv+D5qI4Nblo=";
          # })
        ];

        simple-nixos-mailserver.patches = [
          (fetchpatch {
            name = "feat: add support for DKIM private key files";
            url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/merge_requests/344.diff";
            hash = "sha256-dl2QzFdmQxfbCsnifnSEMxEiqWqgk27vRaCwkg0zugg=";
          })
          (fetchpatch {
            name = "refactor(postfix): fix evaluation warnings";
            url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/merge_requests/436.diff";
            hash = "sha256-TsSGziFQkOhB7EiIALuk0FxP8b58hPcjgvR1zhm1ZfU=";
          })
        ];

        clan-core = {
          patches = [
            (fetchpatch {
              name = ''Reapply "machines update: support `--target-host localhost`"'';
              # Patch from <https://git.clan.lol/jfly/clan-core/compare/main...localhost-as-target-host-without-ssh-take-2>.
              url = "https://git.clan.lol/jfly/clan-core/commit/5623a6440c571da021fff48154223a8782dc79f3.diff";
              hash = "sha256-1V/F24DwQdMQIrVWrfCpQ5tLH8Xw5xw4nTuDiW9JtP4=";
            })
          ];
          inputs.data-mesher.patches = [
            # Relax data-mesher's `NameRegex` to allow for subdomains.
            # See corresponding feature request: <https://git.clan.lol/clan/data-mesher/issues/213>.
            (fetchpatch {
              name = "yolo";
              # Patch from <https://git.clan.lol/jfly/data-mesher/compare/main...more-names>.
              url = "https://git.clan.lol/jfly/data-mesher/commit/065398b48dfb704d2998837b07c9ad804730f1ff.diff";
              hash = "sha256-TBiA/3cD9izRQ5PcXAkG0hYccw+6Q9aZHHXCMY3stSk=";
            })
          ];
        };

        flake-parts.patches = [
          # Workaround for <https://github.com/hercules-ci/flake-parts/issues/299>
          ./patches/flake-parts/add-key-to-nixosModules.patch
        ];
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ ./flake-modules ];
    };
}
