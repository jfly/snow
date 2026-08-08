{
  inputs',
  flake',
  pkgs,
  lib,
  full ? true,
}:

inputs'.nixvim.legacyPackages.makeNixvimWithModule {
  inherit pkgs;
  extraSpecialArgs = { inherit flake'; };

  module = {
    package = inputs'.neovim-nightly-overlay.packages.default.overrideAttrs (oldAttrs: {
      patches = oldAttrs.patches or [ ] ++ [
        # This is a workaround for <https://github.com/neovim/neovim/issues/40631>.
        (pkgs.fetchpatch {
          name = "bg_user_set: hack always return true";
          url = "https://github.com/jfly/neovim/commit/14464f31dcb45849e6f259d80cad55b250e6126e.diff";
          hash = "sha256-PVWy7IV9+osHS4E+EX53/HWvYRsI00s1puxQ3+iiP4U=";
        })
      ];
    });

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
