{ pkgs, fetchpatch }:

let
  vim-dim = (pkgs.vimUtils.buildVimPlugin {
    pname = "vim-dim";
    version = "1.1.1.pre";
    src = pkgs.fetchFromGitHub {
      # This fork of jeffkreeftmeijer/vim-dim contains fixes that work
      # with neovim's updated default colorscheme.
      # See https://github.com/neovim/neovim/issues/26378 for details.
      owner = "jfly";
      repo = "vim-dim";
      rev = "nvim-tweaks";
      sha256 = "sha256-xulPcIyJV4Z7csy1/bPq8v96SkNHH5dj+6xxJwv19eE=";
    };
    meta.homepage = "https://github.com/jeffkreeftmeijer/vim-dim/";
  }).overrideAttrs (oldAttrs: {
    preInstall = ''
      f=colors/dim.vim

      # Tweak the gutter color so it stands out from the background.
      echo 'highlight! LineNr ctermbg=8' >> $f
      echo 'highlight! link SignColumn LineNr' >> $f

      # Link diffRemoved and diffAdded to saner values
      # (this is basically copied from https://github.com/dracula/vim/issues/46)
      echo 'highlight! link diffRemoved DiffDelete' >> $f
      echo 'highlight! link diffAdded DiffAdd' >> $f
    '';
  });
  conflictMarker = "<" + "<<";
  tcommentOverrides = pkgs.writeText "tcomment-overrides" ''
    " Add some missing definitions
    call tcomment#type#Define('bash', '#${conflictMarker} %s')
    call tcomment#type#Define('zsh', '#${conflictMarker} %s')
    call tcomment#type#Define('dockerfile', '#${conflictMarker} %s')

    " Override the c definition
    call tcomment#type#Define('c', tcomment#GetLineC('//${conflictMarker} %s'))

    " Override the Python definition to make black happy
    call tcomment#type#Define('python', '# ${conflictMarker} %s')

    " Override the VIM definition
    call tcomment#type#Define('vim', '"${conflictMarker} %s')
  '';
in

pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped (
  pkgs.neovimUtils.makeNeovimConfig {
    vimAlias = true;
    viAlias = true;
    customRC = builtins.readFile ./vimrc;
    plugins = with pkgs.vimPlugins; [
      fzf-vim
      telescope-nvim
      (MatchTagAlways.overrideAttrs (oldAttrs: {
        patches = [
          # Avoid a really obnoxious warning on Python 3.12: https://github.com/Valloric/MatchTagAlways/issues/51
          (fetchpatch {
            url = "https://patch-diff.githubusercontent.com/raw/Valloric/MatchTagAlways/pull/52.patch";
            sha256 = "sha256-xnS8orNLcTckp57SHulEgRBY9cf5p845ERz9P3Htn54=";
          })
        ];
      }))
      matchit-zip
      # Tweak tcomment so comments for (nearly) all languages get the
      # conflict marker characters I'm so used to having.
      (tcomment_vim.overrideAttrs (oldAttrs: {
        preInstall = ''
          # Some clever regexes to try to replace all the comment
          # strings in
          # https://github.com/tomtom/tcomment_vim/blob/master/autoload/tcomment/types/default.vim
          # This isn't perfect.
          f=autoload/tcomment/types/default.vim

          # Match simple lines like:
          #     call tcomment#type#Define('aap', '# %s')
          sed -i "s/\(Define('.*', *'\S\+\)\( %s.*\)/\1${conflictMarker}\2/" $f

          # Match lines like:
          #     call tcomment#type#Define('cpp', tcomment#GetLineC('// %s'))
          sed -i "s/\(tcomment#GetLineC('\S\+\)\( %s\)/\1${conflictMarker}\2/" $f

          # Match lines like:
          #     call tcomment#type#Define('clojure', {'commentstring': '; %s', 'count': 2})
          sed -i "s/\('commentstring': \+'\S\+\)\( %s\)/\1${conflictMarker}\2/" $f

          cat ${tcommentOverrides} >> $f
        '';
      }))

      # Syntax highlighting + colors
      vim-dim
      vim-polyglot

      lightline-vim
      lightline-bufferline
      vim-fugitive
      vim-rhubarb
      vim-test
      traces-vim
      vim-rsi # readline shortcuts in useful places
      vim-mergetool

      # For James
      nvim-autopairs

      # Linting/autofixing/LSP, etc
      editorconfig-vim
      ale
      nvim-lspconfig
      cmp-nvim-lsp
      cmp-buffer
      nvim-cmp
      null-ls-nvim
      rust-tools-nvim
      fidget-nvim
      trouble-nvim
    ];
  }
)
