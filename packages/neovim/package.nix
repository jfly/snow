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
    package = inputs'.neovim-nightly-overlay.packages.default;

    viAlias = true;
    vimAlias = true;

    imports = (
      if full then
        [
          inputs.sticky-quickfix-nvim.modules.nixvim.default

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
