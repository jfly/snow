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
        # RFC: vim.diagnostic.setqflist improvements
        # https://github.com/neovim/neovim/pull/30868
        (pkgs.fetchpatch {
          url = "https://github.com/neovim/neovim/pull/30868.patch";
          hash = "sha256-BNCpwZ3pfxS2ZH6XMFJOlyMWjIQEZJCAobCN33cvkNQ=";
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
