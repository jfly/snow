{
  inputs,
  inputs',
  system,
  pkgs,
  full ? true,
}:

inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
  inherit pkgs;

  module = {
    package = inputs'.neovim-nightly-overlay.packages.default.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches ++ [
        # Backport of <https://github.com/vim/vim/pull/15841> to Neovim.
        # Hopefully this gets merged!🤞
        (pkgs.fetchpatch {
          url = "https://github.com/neovim/neovim/compare/master...jfly:neovim:backport-add-keep_idx.patch";
          hash = "sha256-oBpd5PAUdyoMSore+i//IYKBn9BRRSHvCs5O6hWlox8=";
        })
      ];
    });

    viAlias = true;
    vimAlias = true;

    imports = (
      if full then
        [
          ./keys
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
