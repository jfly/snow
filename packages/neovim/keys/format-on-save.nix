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
  # So, we disable all LSP servers here.
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
    patches = (oldAttrs.patchs or [ ]) ++ [
      # Workaround for https://github.com/nvimtools/none-ls.nvim/pull/248
      (pkgs.fetchpatch {
        name = "fix: adapt to LSP capability mapping change";
        url = "https://github.com/nvimtools/none-ls.nvim/commit/0fa6ba7686c1f53a7ed8d5fd3d615f7e6be98743.patch";
        hash = "sha256-nMA3FqVniREYP9Yg18YEG+N2sl5l+PtjTITin823hcU=";
      })
    ];
  });
  # plugins.none-ls.settings.debug = true;
  plugins.none-ls.settings.enableLspFormat = true;
  plugins.none-ls.sources.formatting.nix_flake_fmt.enable = true;

}
