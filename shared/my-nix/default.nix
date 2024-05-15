{ pkgs ? import <nixpkgs> { } }:

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
  calibre = pkgs.symlinkJoin {
    name = "calibre";
    paths = [ pkgs.calibre ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/calibre \
        --add-flags "--with-library=~/sync/jeremy/books/calibre"
    '';
  };
  audible-cli = pkgs.audible-cli;
  snowcrypt = pkgs.callPackage ./snowcrypt.nix { };

  ### Text editors
  neovim = pkgs.callPackage ./nvim { };
  # TODO: don't install these globally, instead just make them available
  # to neovim.
  pyright = pkgs.pyright;
  typescript-language-server = pkgs.nodePackages.typescript-language-server;
  vscode = pkgs.vscodium;
  xclip = pkgs.xclip;

  ### Git
  git = pkgs.git;
  github-cli = pkgs.github-cli;

  ### AWS
  awscli2 = pkgs.awscli2;

  ### Desktop
  dunst = pkgs.callPackage ./dunst { };
  xmonad = pkgs.callPackage ../../shared/xmonad { };
  polybar = pkgs.callPackage ./polybar.nix { };
  # I'm not sure if these really ought to be globally installed or not.
  # xmonad is pointing at them directly, but maybe it's nice to be able
  # to easily call them from the command line?
  jvol = pkgs.callPackage ../../shared/jvol { };
  jbright = pkgs.callPackage ../../shared/jbright { };

  ### Development
  xxd = pkgs.xxd;
  rsync = pkgs.rsync;
  mycli = pkgs.callPackage ./mycli { };
  yq = pkgs.yq;
  miller = pkgs.miller;

  ### Debug utils
  strace = pkgs.strace;

  ### Homies
  #### aliases::pdfcrop
  pdftk = pkgs.pdftk;

  ### bin scripts
  paste-list = (pkgs.callPackage ./paste-list { }).paste-list;
}
