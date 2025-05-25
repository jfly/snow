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

    simple-nixos-mailserver.url = "gitlab:simple-nixos-mailserver/nixos-mailserver";

    systems.url = "github:nix-systems/x86_64-linux";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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
            name = "nixos/direnv: fix silent option... again";
            url = "https://github.com/NixOS/nixpkgs/commit/6f9a8cf29359ed29ffc71996b5f27bfca8835d5b.diff";
            hash = "sha256-cn3t99Oa7X1dZtEyOOF1QxnP2dZUpyKL4ujoCjRSPL8=";
          })
          (fetchpatch {
            name = "harper: 0.36.0 -> 0.38.0";
            url = "https://github.com/NixOS/nixpkgs/commit/65e2c1ad85c1dc4735271ed2a9200cae923d1c72.diff";
            hash = "sha256-k6KUAwfbAK9WqIUh1TIcoIzy4WNWm47OSm5fCwCOKy4=";
          })
          # To pull in https://github.com/Automattic/harper/commit/e594a60d433b31872746c98be26e3fbe34d296ed
          ./patches/nixpkgs/harper-unstable.patch
          (fetchpatch {
            name = "fetchpatch: add support for patches to files with apostrophes";
            url = "https://github.com/NixOS/nixpkgs/pull/410320.diff";
            hash = "sha256-3LZclq5mpiyEs4vCHkXNZcYvWMcrITyHuETUhdDGRHQ=";
          })
          # To pull in https://github.com/fish-shell/fish-shell/commit/4ce552bf949a8d09c483bb4da350cfe1e69e3e48
          (fetchpatch {
            name = "fish: 4.0.2 -> 4.1.0-unstable";
            url = "https://github.com/NixOS/nixpkgs/compare/master...jfly:nixpkgs:fish-4.1.0-unstable.diff";
            hash = "sha256-ROfdjyjPmGP7L2uxldeyB6TVUul4IiBxyDz30t+LqFQ=";
          })
        ];

        simple-nixos-mailserver.patches = [
          (fetchpatch {
            name = "feat: add support for DKIM private key files";
            url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/merge_requests/344.diff";
            hash = "sha256-bi13EuDgOMz01bVp5G4H6dKfM0yNnvpFLGrPyVuuEGg=";
          })
        ];

        clan-core = {
          inputs.data-mesher.patches = [
            # Relax data-mesher's NameRegex to allow for subdomains.
            # See corresponding feature request: <https://git.clan.lol/clan/data-mesher/issues/213>.
            (fetchpatch {
              name = "yolo";
              # Patch from <https://git.clan.lol/jfly/data-mesher/compare/main...more-names>.
              url = "https://git.clan.lol/jfly/data-mesher/commit/065398b48dfb704d2998837b07c9ad804730f1ff.diff";
              hash = "sha256-TBiA/3cD9izRQ5PcXAkG0hYccw+6Q9aZHHXCMY3stSk=";
            })
          ];
        };

        treefmt-nix.patches = [
          (fetchpatch {
            name = "Add nixf-diagnose, a Nix linter";
            url = "https://github.com/numtide/treefmt-nix/pull/360.diff";
            hash = "sha256-kXGi49+zHE+ElT07Ef8+74EIqLh7SA6WSz1e5wbOMK8=";
          })
        ];
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ ./flake-modules ];
    };
}
