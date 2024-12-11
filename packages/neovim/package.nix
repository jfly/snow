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
        # feat(diagnostic): store a unique quickfix list per title #31486
        # https://github.com/neovim/neovim/pull/31486
        (pkgs.fetchpatch {
          url = "https://patch-diff.githubusercontent.com/raw/neovim/neovim/pull/31553.patch";
          hash = "sha256-ijkC46FBuopOhdLIAiBx1Whl7+IfpU9Hh+RBaefD6o4=";
        })
        # feat(diagnostic): update existing quickfix list with title if possible
        # https://github.com/neovim/neovim/pull/31486
        (pkgs.fetchpatch {
          url = "https://patch-diff.githubusercontent.com/raw/neovim/neovim/pull/31486.patch";
          hash = "sha256-wSKMwHaQ58jPzBI8pNt2rvP5Ki1a2lwqVG4ubb+GIIA=";
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
