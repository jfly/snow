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
      patches = (if oldAttrs ? patches then oldAttrs.patches else [ ]) ++ [
        # This fixes <https://github.com/neovim/neovim/issues/31923>
        (pkgs.fetchpatch {
          name = ''Revert "refactor(options): set option value for non-current context directly"'';
          url = "https://github.com/neovim/neovim/commit/19c9572d3626cde8503ee9061fa334b73f257b03.patch";
          hash = "sha256-FLpqVn/GGP8tlnsEpgl+f/5TZR0q+/9pu5R7P9wXOs4=";
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
