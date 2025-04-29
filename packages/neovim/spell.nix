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
      local function set_enabled(server_name, enabled)
        if enabled then
          vim.lsp.enable(server_name, true)
          vim.notify("Started " .. server_name, vim.log.levels.INFO)
        else
          vim.lsp.enable(server_name, false)
          vim.notify("Stopped " .. server_name, vim.log.levels.INFO)
        end
      end

      local function toggle_lsp_client(server_name)
        set_enabled(server_name, not vim.lsp.is_enabled(server_name))
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
