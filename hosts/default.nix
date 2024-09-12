{ self, inputs, overlays }:

let
  inherit (inputs)
    agenix
    agenix-rooter
    colmena
    home-manager
    nixos-unstable
    pr-tracker
  ;

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

colmena.lib.makeHive {
  meta = {
    nixpkgs = import nixos-unstable {
      system = "x86_64-linux";
    };

    # Colmena doesn't require it, but put every single host in here. I'd prefer
    # to *not* have a fallback value defined for nixpkgs at all.
    # https://github.com/zhaofengli/colmena/issues/54 tracks that feature
    # request for Colmena.
    nodeNixpkgs = rec {
      clark = patchNixpkgs {
        nixpkgs = import nixos-unstable {
          system = "x86_64-linux";
          inherit overlays;
        };
        genPatches = unpatched: [ ];
      };
      dallben = import nixos-unstable {
        system = "x86_64-linux";
        inherit overlays;
      };
      fflewddur = import nixos-unstable {
        system = "x86_64-linux";
        inherit overlays;
      };
      kent = import nixos-unstable {
        system = "x86_64-linux";
        inherit overlays;
      };
      pattern = patchNixpkgs {
        nixpkgs = (import nixos-unstable {
          system = "x86_64-linux";
          inherit overlays;
        });
        genPatches = unpatched: [
          (unpatched.fetchpatch {
            name = "latest inkscape/silhouette unstable";
            url = "https://github.com/jfly/nixpkgs/commit/653dd896a6cb28f2bc206dc8566348e649bea7d4.patch";
            hash = "sha256-/NJqA1zYJ+uYMQ3tV9zyUG6n4LqeIjcyvvfSr07BVps=";
          })
          # https://github.com/NixOS/nixpkgs/pull/326142
          (unpatched.fetchpatch {
            name = "fix wxPython on Python 3.12";
            url = "https://github.com/NixOS/nixpkgs/compare/master...jfly:nixpkgs:wxpython-fix.patch";
            hash = "sha256-Nv+Di7GNJFSGAclNNCgbDCluPOyDcd7m6jLI2NLRGu8=";
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

    # Use latest nix. There are apparently issues with it [0] [1], but I want
    # to see if they affect me personally.
    # Furthermore, the newer version contains one fix [2] I do care about.
    # [0]: https://github.com/NixOS/nixpkgs/pull/315858
    # [1]: https://github.com/NixOS/nixpkgs/pull/315262
    # [2]: https://github.com/NixOS/nix/pull/9930
    nix.package = pkgs.nixVersions.latest;

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
    inherit self agenix agenix-rooter pr-tracker;
  };
  "dallben" = import dallben/configuration.nix {
    inherit agenix agenix-rooter;
  };
  "fflewddur" = import fflewddur/configuration.nix {
    inherit agenix agenix-rooter;
  };
  "pattern" = import pattern/configuration.nix {
    inherit agenix agenix-rooter home-manager;
  };
  "kent" = import kent/configuration.nix {
    inherit agenix agenix-rooter;
  };
}
