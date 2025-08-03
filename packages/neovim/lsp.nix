{
  imports = [ ./lsp-diagnostic-quirks.nix ];

  # extraConfigLuaPre = ''vim.lsp.set_log_level("debug")'';

  plugins.lspconfig.enable = true;

  lsp.inlayHints.enable = true;

  # Bash
  lsp.servers.bashls.enable = true;

  # Nix
  lsp.servers.nixd.enable = true;

  # Python
  lsp.servers.pyright.enable = true;
  lsp.servers.ruff.enable = true;
  # Implements a workaround for <https://github.com/neovim/neovim/issues/30444>.
  plugins.lsp-diagnostic-quirks.enable = true;

  # Rust
  plugins.rustaceanvim = {
    enable = true;
    settings = {
      default_settings.rust-analyzer = {
        check = {
          command = "clippy";
          allTargets = true;
        };
      };
    };
  };

  # TypeScript/JavaScript
  lsp.servers.ts_ls.enable = true;

  # C/C++
  lsp.servers.clangd.enable = true;

  # Go
  lsp.servers.gopls.enable = true;

  # Lua
  lsp.servers.lua_ls.enable = true;

  # JSON
  lsp.servers.jsonls.enable = true;

  # Typst
  lsp.servers.tinymist.enable = true;
  plugins.typst-preview.enable = true;
}
