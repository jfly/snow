{ lib, helpers, ... }:

{
  plugins.lsp-lines = {
    enable = true;
    luaConfig.post = ''
      vim.diagnostic.config({ virtual_text = false })
    '';
  };

  plugins.lsp.keymaps.extra = [
    {
      key = "<leader>l";
      action = lib.nixvim.mkRaw ''
        function()
          local current = vim.diagnostic.config()
          vim.diagnostic.config({
            virtual_lines = not current.virtual_lines,
            virtual_text = not current.virtual_text,
          })
        end
      '';
    }
    {
      key = "[d";
      action = lib.nixvim.mkRaw ''
        function()
          vim.diagnostic.goto_prev({ float = false })
        end
      '';
    }
    {
      key = "]d";
      action = lib.nixvim.mkRaw ''
        function()
          vim.diagnostic.goto_next({ float = false })
        end
      '';
    }
  ];

  # Populate a quickfix list (and keep it up to date with changes!) with all
  # diagnostics in a workspace.
  # This is basically a simplified (quickfix-only) version of
  # <https://github.com/onsails/diaglist.nvim>.

  extraConfigLuaPre = ''
    do
      vim.api.nvim_create_autocmd('DiagnosticChanged', {
        callback = function(args)
          -- The pcall is a workaround for <https://github.com/neovim/neovim/issues/30867>.
          pcall(vim.diagnostic.setqflist, { open = false })
        end,
      })
    end
  '';

  # Cute diagnostics signs in the gutter =)
  diagnostics.signs = {
    text = helpers.toRawKeys {
      "vim.diagnostic.severity.ERROR" = "󰅚";
      "vim.diagnostic.severity.WARN" = "󰀪";
      "vim.diagnostic.severity.INFO" = "󰌶";
      "vim.diagnostic.severity.HINT" = "";
    };
  };
}
