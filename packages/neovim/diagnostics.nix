{ lib, ... }:

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

  lsp.keymaps = [
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
          vim.diagnostic.jump({ count = -1, float = false })
        end
      '';
    }
    {
      key = "]d";
      action = lib.nixvim.mkRaw ''
        function()
          vim.diagnostic.jump({ count = 1, float = false })
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
        -- Generally don't want it to open on every update.
        opts.qflist.open = opts.qflist.open or false
        vim.diagnostic.setqflist(opts.qflist)
      end,
      hide = function(namespace, bufnr)
        local opts = vim.tbl_extend("force", vim.diagnostic.config().qflist, { open = false })
        vim.diagnostic.setqflist(opts)
      end,
    }

    vim.diagnostic.config({
      qflist = {
        open = false,
        severity = { min = vim.diagnostic.severity.HINT },
      }
    })
  '';

  # Cute diagnostics signs in the gutter =)
  diagnostic.settings.signs = {
    text = lib.nixvim.toRawKeys {
      "vim.diagnostic.severity.ERROR" = "󰅚";
      "vim.diagnostic.severity.WARN" = "󰀪";
      "vim.diagnostic.severity.INFO" = "󰌶";
      "vim.diagnostic.severity.HINT" = "";
    };
  };
}
