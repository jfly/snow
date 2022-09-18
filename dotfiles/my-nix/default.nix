{ pkgs ? (import ../../sources.nix).nixos-unstable { }
, wrapNixGL ? pkgs.callPackage ./wrap-nixgl.nix { }
}:

rec {
  ### Media
  #### Beets
  beets = pkgs.beets;
  abcde = pkgs.abcde;
  mp3val = pkgs.mp3val;
  # TODO: follow up after a while and see if we need these (plugins?) somehow.
  # AddPackage python-pyacoustid # Bindings for Chromaprint acoustic fingerprinting and the Acoustid API
  # AddPackage python-eyed3 # A Python module and program for processing information about mp3 files
  #### MPD
  ashuffle = pkgs.ashuffle;

  ### Ebooks
  # calibre needs to be wrapped with nixGL to run on non-NixOS distributions.
  # See https://github.com/NixOS/nixpkgs/issues/132045 for details.
  calibre = wrapNixGL (pkgs.symlinkJoin {
    name = "calibre";
    paths = [ pkgs.calibre ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/calibre \
        --add-flags "--with-library=~/sync/calibre"
    '';
  });
  knock = import ./knock;

  ### Text editors
  neovim = pkgs.callPackage ./nvim { };
  # TODO: don't install these globally, instead just make them available
  # to neovim.
  pyright = pkgs.pyright;
  vscode = pkgs.vscodium;
  xclip = pkgs.xclip;

  ### Git
  git = pkgs.git;
  github-cli = pkgs.github-cli;

  ### AWS
  awscli2 = pkgs.awscli2;

  ### shell
  shellcheck = pkgs.shellcheck;
  shfmt = pkgs.shfmt;

  ### Desktop
  dunst = pkgs.callPackage ./dunst { };
  xmonad = pkgs.callPackage ../../shared/xmonad { };
  polybar = pkgs.callPackage ./polybar.nix { };
  # kodi needs to be wrapped with nixGL to run on non-NixOS distributions.
  kodi = wrapNixGL (pkgs.callPackage ./kodi { });
  with-alacritty = wrapNixGL (pkgs.callPackage ./with-alacritty { });
  # I'm not sure if these really ought to be globally installed or not.
  # xmonad is pointing at them directly, but maybe it's nice to be able
  # to easily call them from the command line?
  jvol = pkgs.callPackage ../../shared/jvol { };
  jbright = pkgs.callPackage ../../shared/jbright { };

  ### Development
  xxd = pkgs.xxd;
  rsync = pkgs.rsync;
  mycli = pkgs.callPackage ./mycli { };
  shtuff = pkgs.callPackage ./shtuff { };
  yq = pkgs.yq;
  miller = pkgs.miller;

  ### Debug utils
  strace = pkgs.strace;

  ### Homies
  #### aliases::pdfcrop
  pdftk = pkgs.pdftk;

  ### bin scripts
  paste-list = (pkgs.callPackage ./paste-list { }).paste-list;

  home-manager = (pkgs.callPackage (import ../../sources.nix).home-manager-modules
    {
      configuration = import ../../shared/home.nix {
        username = "jeremy";
      };
      check = false;
    }).activationPackage;
}
