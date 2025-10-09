{ lib, config, ... }:
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

  # TypeScript/JavaScript/Vue
  lsp.servers.ts_ls.enable = true;
  lsp.servers.vue_ls.enable = true;
  # This is kind of tricky: `vue_ls` requires that a vue-specific plugin be
  # added to `ts_ls`. This is documented on
  # <https://github.com/vuejs/language-tools/wiki/Neovim>, and nixvim
  # does have this logic built into their older `plugins.lsp` api:
  # <https://github.com/nix-community/nixvim/blob/3fa0e487260af16dde609940e49c3ddc6c31c6ed/plugins/lsp/language-servers/default.nix#L155-L185>.
  # TODO: figure out if this can be PR-ed to nixvim, see <https://github.com/nix-community/nixvim/issues/3773>.
  lsp.servers.ts_ls.settings = {
    filetypes = [
      "vue"
      # Unfortunately we have to explicitly list the filetypes that this LSP works on.
      # I'm not entirely sure why this doesn't merge, see
      # <https://github.com/nix-community/nixvim/blob/3fa0e487260af16dde609940e49c3ddc6c31c6ed/plugins/lsp/language-servers/default.nix#L121-L122>
      # for a similar version of this.
      "javascript"
      "javascriptreact"
      "javascript.jsx"
      "typescript"
      "typescriptreact"
      "typescript.tsx"
    ];
    init_options.plugins = [
      {
        name = "@vue/typescript-plugin";
        location = "${lib.getBin config.lsp.servers.vue_ls.package}/lib/language-tools/packages/language-server";
        languages = [ "vue" ];
      }
    ];
  };

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
