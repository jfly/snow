{ lib, ... }:

let
  inherit (lib.nixvim) mkRaw;
in
{
  # Format on save.
  plugins.lsp-format.enable = true;
  # By default, lsp-format is configured to try to format with *all*
  # attached LSPs. I don't want that to happen: if I'm hacking on some
  # random repository, I don't want to suddently reformat all their code.
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
  # plugins.none-ls.settings.debug = true;
  plugins.none-ls.settings.enableLspFormat = true;
  # Note: nixvim will generate a nice nixified option for this once
  # https://github.com/nvimtools/none-ls.nvim/pull/192 lands in none-ls.
  plugins.none-ls.settings.sources = [ ''require("null-ls").builtins.formatting.nix_flake_fmt'' ];

}
