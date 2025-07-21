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
        # This is a workaround for https://github.com/neovim/neovim/issues/33864
        (pkgs.fetchpatch {
          name = "fix(lsp): ignore diagnostics from a LSP we're detached from";
          url = "https://github.com/neovim/neovim/commit/d42ee194a3d249ac90cb5548fa41281bbe9eab82.patch";
          hash = "sha256-rYLZk4HXD0FhuPNA22WER1g+yTYcfyRU/uX4t3SIj3s=";
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
    ]
    ++ lib.optionals full [
      ./lsp.nix
    ];
  };
}
