{ lib, helpers, ... }:

{
  plugins.lsp-lines = {
    enable = true;
    luaConfig.post =
      # lua
      ''
        vim.diagnostic.config({
          virtual_text = true,
          virtual_lines = false,
        })
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
    vim.diagnostic.handlers.qflist = {
      show = function(_, _, _, opts)
        -- Generally don't want it to open on every update
        opts.qflist.open = opts.qflist.open or false
        vim.diagnostic.setqflist(opts.qflist)
      end
    }

    vim.diagnostic.config({
      qflist = {
        open = false,
        severity = { min = vim.diagnostic.severity.HINT },
      }
    })
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
