{ lib, pkgs, ... }:

let
  inherit (lib.nixvim) mkRaw;
in
{
  # Format on save.
  plugins.lsp-format.enable = true;
  # By default, lsp-format is configured to try to format with *all*
  # attached LSPs. I don't want that to happen: if I'm hacking on some
  # random repository, I don't want to suddenly reformat all their code.
  # So, we disable all lsp servers here.
  plugins.lsp-format.lspServersToEnable = "none";

  keymaps = [
    {
      key = "<leader>ta";
      options.desc = "Toggle autoformatting";
      action = mkRaw ''
        function()
          local lsp_format = require("lsp-format")

          lsp_format.disabled = not lsp_format.disabled

          local message
          if lsp_format.disabled then
            message = "Autoformatting is off"
          else
            message = "Autoformatting is on"
          end
          vim.notify(message, vim.log.levels.INFO)
        end
      '';
    }
  ];

  # Instead, configure none-ls to be the only formatter used by lsp-format.
  plugins.none-ls.enable = true;
  plugins.none-ls.package = pkgs.vimPlugins.none-ls-nvim.overrideAttrs (oldAttrs: {
    patches = (if oldAttrs ? patches then oldAttrs.patches else [ ]) ++ [
      # https://github.com/nvimtools/none-ls.nvim/commit/43b7bb58793b7d2e892656accf393f767c508a70
      (pkgs.fetchpatch {
        name = "helpers: make dynamic_command async";
        url = "https://github.com/nvimtools/none-ls.nvim/commit/43b7bb58793b7d2e892656accf393f767c508a70.diff";
        hash = "sha256-vQEhPLz7v9fAqcGaV572rnvzFEG7ZVmmv2uuLp+pIWc=";
      })
      # https://github.com/nvimtools/none-ls.nvim/pull/220
      (pkgs.fetchpatch {
        name = "Run `dynamic_command` immediately when opening a buffer";
        url = "https://github.com/nvimtools/none-ls.nvim/commit/40dc2e983560acaea29d6312b33fafba37b0c272.diff";
        hash = "sha256-n+3e9s2fH9CcH3aIf3HxtSYqeT0kW/azXifevbR5VU0=";
      })
      # https://github.com/nvimtools/none-ls.nvim/pull/192
      (pkgs.fetchpatch {
        name = "Add 'nix flake fmt' builtin formatter";
        url = "https://patch-diff.githubusercontent.com/raw/nvimtools/none-ls.nvim/pull/192.diff";
        hash = "sha256-F32gixa54g2o2G+L6ZGJv7+ldTbYoszvasOgCdtPwlE=";
      })
    ];
  });
  # plugins.none-ls.settings.debug = true;
  plugins.none-ls.settings.enableLspFormat = true;
  # Note: nixvim will generate a nice nixified option for this once
  # https://github.com/nvimtools/none-ls.nvim/pull/192 lands in none-ls.
  plugins.none-ls.settings.sources = [ ''require("null-ls").builtins.formatting.nix_flake_fmt'' ];

}
