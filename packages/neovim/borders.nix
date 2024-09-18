{ lib, helpers, ... }:

# There isn't currently a convinient way to restyle *all* windows in Neovim.
# [borderline.nvim] seems to be trying to tackle the problem, but its README
# scared me away ("This project is still a work in progress").
#
# In other news, it looks like there's some hope for core Neovim to get support
# for [global controlling of floating windows
# borders](https://github.com/neovim/neovim/issues/20202).
#
# For now, I just manually re-configure all the types of borders I tend to see,
# as described in <https://vi.stackexchange.com/a/39075>.
#
# [borderline.nvim]: https://github.com/mikesmithgh/borderline.nvim
let
  inherit (lib.nixvim) mkRaw;
  border = "rounded";
in
{
  diagnostics.float.border = border;
  plugins.which-key.settings.win.border = border;
  plugins.rustaceanvim.settings.tools.float_win_config.border = border;

  plugins.cmp.settings.window.documentation = mkRaw ''cmp.config.window.bordered()'';

  extraConfigLua = ''
    do
      local border = ${helpers.toLuaObject border};
      local ms = vim.lsp.protocol.Methods

      function handlerWithBorder(handler)
        return vim.lsp.with(handler, { border = border })
      end

      vim.lsp.handlers[ms.textDocument_hover] = handlerWithBorder(ms.textDocument_hover)
      vim.lsp.handlers[ms.textDocument_signatureHelp] = handlerWithBorder(vim.lsp.handlers.signature_help)
      require('lspconfig.ui.windows').default_options.border = border
    end
  '';
}
