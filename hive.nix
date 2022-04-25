{
  meta = {
    nixpkgs = (import ./sources.nix).pkgs-unstable {};

    # Colmena doesn't require it, but put every single host in here. I'd prefer
    # to *not* have a fallback value defined for nixpkgs at all.
    # https://github.com/zhaofengli/colmena/issues/54 tracks that feature
    # request for Colmena.
    nodeNixpkgs = rec {
      clark = (import ./sources.nix).pkgs-21_11 {
        overlays = import ./overlays;
      };
      dallben = (import ./sources.nix).pkgs-unstable {
        overlays = import ./overlays;
      };
      fflewddur = (import ./sources.nix).pkgs-21_11 {
        overlays = import ./overlays;
      };
      fflam = (import ./sources.nix).pkgs-21_11 {
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

    users.groups.media = { gid=1002; };
  };

  "clark" = import clark/configuration.nix;
  "dallben" = import dallben/configuration.nix;
  "fflewddur" = import fflewddur/configuration.nix;
  "fflam" = import fflam/configuration.nix;
}
