{
  description = "snow";

  nixConfig = {
    abort-on-warn = true;
  };

  inputs = {
    brbd-sync = {
      url = "github:jfly/brbd-sync";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.flake-parts.follows = "flake-parts";
    };

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

    google-dav-proxy.url = "github:jfly/google-dav-proxy";

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

    # See notes about czkawka in <machines/fflewddur/remote-desktop.nix> for
    # why we have this input.
    nixpkgs-25_05.url = "github:NixOS/nixpkgs/nixos-25.05";

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

    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";

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
            name = "vaultwarden: 1.35.2 -> 1.35.3";
            url = "https://github.com/NixOS/nixpkgs/commit/01696241af8a576337634776b012881730b364c2.diff";
            hash = "sha256-KSbsEicIwBWfLgxr/hrB4WM9DJDjo65oL8f+iEx1A/s=";
          })
          (fetchpatch {
            name = "python3Packages.cec: init at 0.2.8, cecdaemon: init at 1.0.0-unstable-2025-11-12";
            url = "https://github.com/NixOS/nixpkgs/pull/464399.diff";
            hash = "sha256-Xuhx1R8OvMR+KPNAMrJ5MzZFHntO37EfaRjw7jt6l4k=";
          })
          (fetchpatch {
            name = "bcompare: 4.4.7.28397 -> 5.1.2.31185";
            url = "https://github.com/NixOS/nixpkgs/pull/435513.diff";
            hash = "sha256-oRxDDjGP6Kaeh70+hls0oL2LbCOrwsJdy/PONEPA/n4=";
          })
          ./patches/nixpkgs/bcompare-xorg-deprecations.patch
          (fetchpatch {
            name = "odmpy: init at 0.8.1, python3.pkgs.iso639-lang: init at 2.6.3";
            url = "https://github.com/NixOS/nixpkgs/pull/460870.diff";
            hash = "sha256-kqbEnhJkSh00c7bKcft22deYFP7x6oYB2DivADb4R9Y=";
          })
          (fetchpatch {
            name = "miniflux: add options for all secret files";
            url = "https://github.com/NixOS/nixpkgs/compare/master...jfly:miniflux-add-client-secret-files.diff";
            hash = "sha256-lASXMmHr3vD9R3xCWTiJ/cA9J3KCi66EDZwJtLjmRKw=";
          })
          (fetchpatch {
            name = "nixos/prometheus/mqtt-exporter: add `package` option";
            url = "https://github.com/NixOS/nixpkgs/pull/485251.diff";
            hash = "sha256-6DfWKZKF1Scx5YD60V4RwxDJZmWj0o/m+rzA8CH+Rtw=";
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
            hash = "sha256-+sgLfoEAGNVgjwQZc4At3ibcW8c9/Zk7g5yiqKdCsdY=";
          })
        ];

        clan-core = {
          patches = [
            (fetchpatch {
              name = ''Reapply "machines update: support `--target-host localhost`"'';
              url = "https://git.clan.lol/clan/clan-core/pulls/4851.diff";
              hash = "sha256-thbXiwgS/LePqKtM86iPF5kANxbxZb5zR3L+MexKZ/w=";
            })
            # We need to allow vars definitions to differ across machines.
            # See the "Ensure the oauth secrets are readable by the Kanidm
            # service" comment in machines/fflewddur/kanidm/default.nix for
            # an explanation why.
            # TODO: rework the kanidm module to be able to use systemd's
            # `LoadCredential` instead (see the `postStartScript`), and get rid of this.
            ./patches/clan-core/allow-differing-shared-generators.patch
            # Clan's intelligent network discovery does not have a mechanism to
            # pick a username:
            # <https://git.clan.lol/clan/clan-core/issues/5812>, and the
            # explicit `targetHost` we specify does not work due to
            # <https://git.clan.lol/clan/clan-core/issues/5813>.
            # As an incredibly quick and dirty hack, we just hardcode clan to
            # use the correct username instead.
            ./patches/clan-core/username-hack.patch
            # Workaround for <https://git.clan.lol/clan/clan-core/issues/4624>.
            ./patches/clan-core/read-build-host-from-env-var.patch
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
