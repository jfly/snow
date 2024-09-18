{
  inputs,
  inputs',
  system,
  pkgs,
}:

inputs.nixvim.legacyPackages.${system}.makeNixvimWithModule {
  inherit pkgs;

  module = {
    package = inputs'.neovim-nightly-overlay.packages.default;

    viAlias = true;
    vimAlias = true;

    imports = [
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
      ./diagnostics.nix
      ./borders.nix
      ./spell.nix
      ./notifications.nix
      ./completion
    ];
  };
}
