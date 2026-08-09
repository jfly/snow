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
          url = "https://github.com/jfly/neovim/commit/d6305eac9a76c829fb46fda85d64ae73802f174b.diff";
          hash = "sha256-FPpPHwgNqwo1GnbqHnbUuJCLAtMqxM3NU5MdJjtgNss=";
        })
        (pkgs.fetchpatch {
          name = "feat(dir): sort and filter listings";
          url = "https://github.com/neovim/neovim/pull/41138.diff";
          hash = "sha256-WkY1K4gmVGY45rFe8M5JaYM5UtiNbenTj0g64VKGPII=";
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
