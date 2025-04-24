{
  lib,
  flake',
  ...
}:

let
  inherit (lib.nixvim) mkRaw;
in
{
  plugins.lsp.servers.harper_ls.enable = true;

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
          client:stop()
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
