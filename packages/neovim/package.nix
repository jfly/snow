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
        (pkgs.fetchpatch {
          name = "feat(lsp): add a `vim.lsp.is_enabled`";
          url = "https://github.com/neovim/neovim/pull/33703.patch";
          hash = "sha256-QyJ3nthQIedCQJTWHoD6SZDR0FXzQpgRBGr2ZsHHxII=";
        })
        (pkgs.fetchpatch {
          name = "feat(lsp): automatically stop LSP clients when filetype changes";
          url = "https://github.com/neovim/neovim/pull/33707.patch";
          hash = "sha256-ElOK4esm6sJZXksxX4L3AzUegsEio+AR0TCBXZryxaM=";
        })
        # TODO: send in a PR for this after PR33707 (above) lands.
        # https://github.com/jfly/neovim/tree/diagnostics-race-while-detaching
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

    imports = (
      if full then
        [
          ./keys.nix
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
