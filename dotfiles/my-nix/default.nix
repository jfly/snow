{ pkgs ? (import ../../sources.nix).nixos-unstable { }
, wrapNixGL ? pkgs.callPackage ./wrap-nixgl.nix { }
,
}:

{
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
  calibre = wrapNixGL pkgs.calibre;
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

  # TODO: isolate to fixinputs
  capslockx = pkgs.callPackage ../../shared/capslockx { };

  # TODO: remove one we're fully on nixos and no longer need this in our path
  #       (it's referenced in xinitrc).
  volnoti = pkgs.callPackage ../../shared/volnoti { };
}
