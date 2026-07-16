{
  inputs',
  flake',
  pkgs,
  lib,
  full ? true,
}:

inputs'.nixvim.legacyPackages.makeNixvimWithModule {
  inherit pkgs;

  module = {
    package = inputs'.neovim-nightly-overlay.packages.default.overrideAttrs (oldAttrs: {
      patches = (if oldAttrs ? patches then oldAttrs.patches else [ ]) ++ [
        # This is a fix for <https://github.com/neovim/neovim/issues/40631>.
        (pkgs.fetchpatch {
          name = "fix(lua): preserve startup source context";
          url = "https://github.com/neovim/neovim/pull/40647.diff";
          hash = "sha256-Ds7OuK9jnKEkCHBHFZqRAGbrcpKF076XB4TZcRnJrLI=";
        })
      ];
    });
    _module.args.flake' = flake';

    viAlias = true;
    vimAlias = true;

    imports = [
      ./keys.nix
      ./clipboard.nix
      ./numbers.nix
      ./formatting.nix
      ./format-on-save.nix
      ./syntax.nix
      ./colorscheme.nix
      ./search.nix
      ./git.nix
      ./vimtest.nix
      ./lightline.nix
      ./hacking.nix
      ./notetaking.nix
      ./markdown.nix
      ./quickfix.nix
      ./diagnostics.nix
      ./borders.nix
      ./spell.nix
      ./notifications.nix
      ./completion
      ./fuzzy-find.nix
    ]
    ++ lib.optionals full [
      ./lsp.nix
    ];
  };
}
