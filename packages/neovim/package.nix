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
        # Yay, nothing right now!
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
          ./markdown.nix
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
