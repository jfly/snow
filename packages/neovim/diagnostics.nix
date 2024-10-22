{ helpers, ... }:

{
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
