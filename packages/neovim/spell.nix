{ lib, flake', ... }:

let
  inherit (lib.nixvim) mkRaw;
in
{
  plugins.lsp.servers.harper_ls.enable = true;
  plugins.lsp.servers.harper_ls.extraOptions = {
    # Add `nix` to the list of filetypes harper-ls runs on.
    # This requires using our forked version of harper with support for nix.
    # TODO: upstream this to lspconfig once https://github.com/elijah-potter/harper/pull/244 lands.
    # TODO: change to `.configs` once we pull in a version of lspconfig with
    # <https://github.com/neovim/nvim-lspconfig/commit/bedb2a0df105f68a624a49b867f269b6d55a2c89>.
    filetypes = mkRaw ''
      vim.list_extend({"nix"}, require('lspconfig.server_configurations.harper_ls').default_config.filetypes)
    '';
  };
  # Use our patched version of harper-ls. See `packages/harper/package.nix` for details.
  plugins.lsp.servers.harper_ls.package = flake'.packages.harper;

  extraConfigLuaPre = ''
    local snow_lsp = {}
    do
      local util = require('lspconfig.util')

      local function find_lsp_client(server_name)
        local servers_on_buffer = util.get_lsp_clients { bufnr = current_buf }
        for _, client in ipairs(servers_on_buffer) do
          if client.config.name == server_name then
            return client
          end
        end

        return nil
      end

      local function toggle_lsp_client(server_name)
        local client = find_lsp_client(server_name)

        if client then
          client.stop()
          vim.notify("Stopped " .. server_name, vim.log.levels.INFO)
        else
          local config = require('lspconfig.configs')[server_name]
          config.launch()
          vim.notify("Started " .. server_name, vim.log.levels.INFO)
        end
      end

      snow_lsp.toggle_client = toggle_lsp_client
    end
  '';

  keymaps = [
    {
      key = "<leader>s";
      options.desc = "Toggle spelling";
      action = mkRaw ''
        function()
          snow_lsp.toggle_client("harper_ls")
        end
      '';
    }
  ];
}
