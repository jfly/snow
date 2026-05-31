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

    jnix = {
      url = "github:jfly/jnix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.git-hooks-nix.follows = "git-hooks-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.treefmt-nix.follows = "treefmt-nix";
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
              name = "nixos/oauth2-proxy: fix warning condition";
              url = "https://github.com/NixOS/nixpkgs/commit/deaf02d3d250018ccc0587cc7124a3d12836448a.diff";
              hash = "sha256-UVDibIqDQ04t3iY3SxLhkt+OsA6cmqth9d/6/mtgWw4=";
            })
            (fetchpatch {
              name = ''Revert "nixos/blueman: Add option to enable Blueman tray applet" (#521288)'';
              url = "https://github.com/NixOS/nixpkgs/commit/3c53cb036ac5dad5d190a130b970c6f8ffcf89fe.diff";
              hash = "sha256-VVymVOaX9GTkOQ8ObLUOOYA6RML62JYimQ3bzb/4GEs=";
            })
            (fetchpatch {
              name = "immichframe: refactor, add updateScript, and 1.0.29.0 -> 1.0.33.0";
              url = "https://github.com/NixOS/nixpkgs/pull/513463.diff";
              hash = "sha256-qvzsGe5aMfxwuytIvYYDKWhFMgwAZ/FWSBmIANAkdG8=";
            })
            (fetchpatch {
              name = "python3Packages.cec: init at 0.2.8, cecdaemon: init at 1.0.0-unstable-2025-11-12";
              url = "https://github.com/NixOS/nixpkgs/pull/464399.diff";
              hash = "sha256-Xuhx1R8OvMR+KPNAMrJ5MzZFHntO37EfaRjw7jt6l4k=";
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
          ];

          openwrt-imagebuilder.patches = [
            (fetchpatch {
              name = "update hashes";
              url = "https://github.com/astro/nix-openwrt-imagebuilder/compare/main...jfly:nix-openwrt-imagebuilder:update-hashes.diff";
              hash = "sha256-opTQ0guDgJdwPkBnXQWKpE3nihQQYhCIt0t4QddDxmc=";
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
        };
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ ./flake-modules ];
    };
}
