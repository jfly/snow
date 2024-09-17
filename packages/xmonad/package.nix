{ flake', pkgs }:

# This was largely copied from nixos/modules/services/x11/window-managers/xmonad.nix
let
  haskellPkgs = pkgs.haskellPackages;
  xmonadAndPackages = [
    haskellPkgs.xmonad
    haskellPkgs.xmonad-contrib
  ];
  xmonadEnv = haskellPkgs.ghcWithPackages (p: xmonadAndPackages);
  xmonadHs = pkgs.substituteAll {
    src = ./xmonad.hs;
    inherit (pkgs) libnotify;
    inherit (flake'.packages)
      autoperipherals
      colorscheme
      jbright
      jscrot
      jvol
      setbg
      ;
  };
  configured = pkgs.writers.writeHaskellBin "xmonad" {
    libraries = xmonadAndPackages;
  } xmonadHs;
in

pkgs.runCommandLocal "xmonad"
  {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  }
  ''
    install -D ${xmonadEnv}/share/man/man1/xmonad.1.gz $out/share/man/man1/xmonad.1.gz
    makeWrapper ${configured}/bin/xmonad $out/bin/xmonad \
        --set XMONAD_XMESSAGE "${pkgs.xorg.xmessage}/bin/xmessage"
  ''
