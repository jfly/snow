{
  inputs,
  inputs',
  flake',
  system,
  pkgs,
  full ? true,
}:

inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
  inherit pkgs;

  module = {
    package = inputs'.neovim-nightly-overlay.packages.default.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [
        # feat(diagnostic): `vim.diagnostic.setqflist` improvements
        # https://github.com/neovim/neovim/pull/30868
        (pkgs.fetchpatch {
          url = "https://github.com/neovim/neovim/commit/7579af3c514c44581fe33b5c03660cdfda7d658e.patch";
          hash = "sha256-pyHDvOQde8DSX1P/O+mM5GWkUQ8Mzmcwo629QwfBBIw=";
        })
        # fix(diagnostic): only update stored quickfix id when we create a new quickfix
        # https://github.com/neovim/neovim/pull/31466
        (pkgs.fetchpatch {
          url = "https://patch-diff.githubusercontent.com/raw/neovim/neovim/pull/31466.patch";
          hash = "sha256-/n8qAouJdXmM72Xn8cF578e4Pg63Z+FIMMQ19OlMNrs=";
        })
        # feat(diagnostic): store a unique quickfix list per title
        # https://github.com/neovim/neovim/pull/31486
        (pkgs.fetchpatch {
          url = "https://patch-diff.githubusercontent.com/raw/neovim/neovim/pull/31486.patch";
          hash = "sha256-gaHkA61ilcdURYAfWSNmeAPmfGWCte99LfUEDvFgzaU=";
        })
      ];
    });

    _module.args.flake' = flake';

    viAlias = true;
    vimAlias = true;

    imports = (
      if full then
        [
          ./keys
          ./numbers.nix
          ./formatting.nix
          ./syntax.nix
          ./colorscheme.nix
          ./search.nix
          ./git.nix
          ./vimtest.nix
          ./lightline.nix
          ./hacking.nix
          ./notetaking.nix
          ./lsp.nix
          ./quickfix.nix
          ./diagnostics.nix
          ./borders.nix
          ./spell.nix
          ./notifications.nix
          ./completion
        ]
      else
        [ ]
    );
  };
}
