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
      patches = oldAttrs.patches ++ [
        # This patch fixes <https://github.com/neovim/neovim/issues/30867>
        # "fix(exit): close memfiles after processing events"
        (pkgs.fetchpatch {
          url = "https://github.com/neovim/neovim/commit/8c2d45be77299d6eb70165697bc5c29898cdb25e.patch";
          hash = "sha256-pTHSFGt6rQva2HW7bc/EmQsPwIB2DQQz2fzNO128ztA=";
        })
        # RFC: vim.diagnostic.setqflist improvements
        # https://github.com/neovim/neovim/pull/30868
        (pkgs.fetchpatch {
          url = "https://github.com/neovim/neovim/pull/30868.patch";
          hash = "sha256-WpTHlR2PeLyjSesTy98I8X19fEjSDBp2Z9QsUuej368=";
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
