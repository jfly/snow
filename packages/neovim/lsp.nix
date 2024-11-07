{
  imports = [ ./lsp-diagnostic-quirks.nix ];

  # extraConfigLuaPre = ''vim.lsp.set_log_level("debug")'';

  plugins.lsp.enable = true;
  plugins.lsp.inlayHints = true;

  # Bash
  plugins.lsp.servers.bashls.enable = true;

  # Nix
  plugins.lsp.servers.nixd.enable = true;

  # Python
  plugins.lsp.servers.pyright.enable = true;
  plugins.lsp.servers.ruff.enable = true;
  # Implements a workaround for <https://github.com/neovim/neovim/issues/30444>.
  plugins.lsp.diagnostic-quirks.enable = true;

  # Rust
  plugins.rustaceanvim.enable = true;

  # TypeScript/JavaScript
  plugins.lsp.servers.ts_ls.enable = true;

  # C/C++
  plugins.lsp.servers.clangd.enable = true;

  # Go
  plugins.lsp.servers.gopls.enable = true;
}
