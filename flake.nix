{
  description = "snow";

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
      inputs.systems.follows = "systems";
    };

    devshell-init = {
      url = "github:jfly/devshell-init";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-input-patcher = {
      # TODO: finish <https://github.com/jfly/flake-input-patcher/pull/3> and
      #       switch back to main.
      # url = "github:jfly/flake-input-patcher";
      url = "github:jfly/flake-input-patcher/follows";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    google-dav-proxy = {
      url = "github:jfly/google-dav-proxy";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

    simple-nixos-mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systemctl-restore = {
      url = "github:jfly/systemctl-restore";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    systems.url = "github:nix-systems/x86_64-linux";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treeport = {
      url = "github:jfly/treeport";
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

      inputs = patcher.patch {
        inherit unpatchedInputs;
        flakePath = ./.;
        patchSpec = {
          nixpkgs.patches = [
            # We really need some way to suppress "expected" warnings. I'm doing
            # this so I can leave `abort-on-warn` enabled.
            ./patches/nixpkgs/suppress-x86_64-darwin-warning.patch
            (fetchpatch {
              name = "mqtt-exporter: 1.11.2 -> 1.12.1";
              url = "https://github.com/NixOS/nixpkgs/commit/cb45eefc904a8377f5b3f86e4ade35f0b42862fd.diff";
              hash = "sha256-EMtH6QtWkhrf0PnEph/yagSKgoxOmqAv+ZX1YnbleJM=";
            })
            (fetchpatch {
              name = "vaultwarden: 1.35.8 -> 1.36.0";
              url = "https://github.com/NixOS/nixpkgs/pull/516109.diff";
              hash = "sha256-y/3RoCbw7rPT12qj0gbTFAVx0EZhDB+LJ2L9ha0ol0Y=";
            })
            (fetchpatch {
              name = "tshark: fix hash";
              url = "https://github.com/NixOS/nixpkgs/commit/0aa49fb3431c18346103889381ae91120f526626.diff";
              hash = "sha256-04nZuCtJoZHA7MEUr3e0v9Q2cRg6sjjAVKFRZG0ux+A=";
            })
            (fetchpatch {
              name = "nixos/blueman: remove duplicate ExecStart";
              url = "https://github.com/NixOS/nixpkgs/pull/516323.diff";
              hash = "sha256-djHHpBM0M+9SNL1/HPi8PsfO2w3zzgn88vQy45tPCEQ=";
            })
            (fetchpatch {
              name = "nixos/home-assistant: migrate lovelace config to dashboards format";
              url = "https://github.com/NixOS/nixpkgs/pull/490587.diff";
              hash = "sha256-FHkszUPYil4Jb0HGGfEe+DbeMSLVS/V4vu9YfJvMXCs=";
            })
            (fetchpatch {
              name = "immichframe: refactor, add updateScript, and 1.0.29.0 -> 1.0.33.0";
              url = "https://github.com/NixOS/nixpkgs/pull/513463.diff";
              hash = "sha256-9Fvm6yN8qA3mu23ZM1u45y8bL0kBz/j1d0cu+GQJlnc=";
            })
            (fetchpatch {
              name = "python3Packages.cec: init at 0.2.8, cecdaemon: init at 1.0.0-unstable-2025-11-12";
              url = "https://github.com/NixOS/nixpkgs/pull/464399.diff";
              hash = "sha256-Xuhx1R8OvMR+KPNAMrJ5MzZFHntO37EfaRjw7jt6l4k=";
            })
            (fetchpatch {
              name = "bcompare: 4.4.7.28397 -> 5.2.0.31950";
              url = "https://github.com/NixOS/nixpkgs/pull/435513.diff";
              hash = "sha256-qtjB3cf07CMQW82Ypvik5ike//eN8b4zA7bqASO6Cng=";
            })
            (fetchpatch {
              name = "odmpy: init at 0.8.1, python3.pkgs.iso639-lang: init at 2.6.3";
              url = "https://github.com/NixOS/nixpkgs/pull/460870.diff";
              hash = "sha256-kqbEnhJkSh00c7bKcft22deYFP7x6oYB2DivADb4R9Y=";
            })
            (fetchpatch {
              name = "miniflux: add options for all secret files";
              url = "https://github.com/NixOS/nixpkgs/compare/master...jfly:miniflux-add-client-secret-files.diff";
              hash = "sha256-+PLcqH2kxXzx7ykvZRHgnUM4T9lEwpdIaLtaqxC6Lkw=";
            })
            (fetchpatch {
              name = "nixos/actkbd: switch to Type=exec rather than forking";
              url = "https://github.com/NixOS/nixpkgs/pull/500207.diff";
              hash = "sha256-3I/VnmMF05KIYMrUBRnqsh+eqCwCKejao6AKy/JEjZo=";
            })
            (fetchpatch {
              name = "mcg: init at 4.0.2";
              url = "https://github.com/NixOS/nixpkgs/pull/509402.diff";
              hash = "sha256-dfv8NPSqeS51a8b/7GZueZxzEmNDK1rQ3cYk9dMcj34=";
            })
            (fetchpatch {
              name = "gscan2pdf: disable a failing test";
              url = "https://github.com/NixOS/nixpkgs/pull/516066.diff";
              hash = "sha256-C918ZJSr+pZUavfr+wHb6i9gw5trm7W92Os6w0jRhX4=";
            })
          ];

          openwrt-imagebuilder.patches = [
            (fetchpatch {
              name = "update hashes";
              url = "https://github.com/astro/nix-openwrt-imagebuilder/compare/main...jfly:nix-openwrt-imagebuilder:update-hashes.diff";
              hash = "sha256-HzLGZAwMC4yiG0rJ34vs8TKsKglzMYRZBf+kn8RBgF0=";
            })
          ];

          clan-core.patches = [
            # (fetchpatch {
            #   name = ''Reapply "machines update: support `--target-host localhost`"'';
            #   url = "https://git.clan.lol/clan/clan-core/pulls/4851.diff";
            #   hash = "sha256-DdCkJHqBrn2s7jsNyXq7ASa2jV0z87VdBZH4K5FFl/A=";
            # })
            # NOTE: not using fetchpatch (as above) right now because
            # git.clan.lol recently started requiring authentication to
            # download diffs. I've asked about relaxing that constraint, we'll
            # see if it changes in the future.
            # https://git.clan.lol/clan/clan-core/pulls/4851
            ./patches/clan-core/support-target-host-localhost.patch
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

          flake-parts.patches = [
            # Workaround for <https://github.com/hercules-ci/flake-parts/issues/299>
            ./patches/flake-parts/add-key-to-nixosModules.patch
          ];

          with-alacritty.patches = [
            (fetchpatch {
              name = "Remove deprecated `pytestFlagsArray`";
              url = "https://github.com/FatBoyXPC/with-alacritty/pull/5.diff";
              hash = "sha256-7mGb6sDrOq39SnMIC2c5w8qI6DXxKhUSwgNPXTgjRwk=";
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
