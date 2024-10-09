{
  imports = [ ./lsp-diagnostic-quirks.nix ];

  plugins.lsp.enable = true;

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
}
