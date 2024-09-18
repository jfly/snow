{
  config,
  lib,
  helpers,
  ...
}:

let
  inherit (lib) types;
  inherit (lib.nixvim) mkRaw;
  inherit (lib.options) mkOption;
  cfg = config.snow.diagnostics;
in

{
  options = {
    snow.diagnostics.toggle_list_key = mkOption {
      description = "The key to toggle visibility of a list of diagnostics.";
      type = types.str;
      default = null;
    };
  };

  config = {
    # Nice way to get a list of all diagnostics. Especially useful when dealing
    # with multiple files in a workspace.
    # This is re-inventing the quickfix list. TODO: Look into [diaglist] instead.
    # [diaglist]: https://github.com/onsails/diaglist.nvim
    plugins.trouble.enable = true;
    plugins.trouble.settings.focus = true;
    keymaps = [
      {
        key = cfg.toggle_list_key;
        options.desc = "Toggle code diagnostics list";
        action = mkRaw ''
          function()
            require("trouble").toggle("diagnostics")
          end
        '';
      }
    ];

    # Cute diagnostics signs in the gutter =)
    diagnostics.signs = {
      text = helpers.toRawKeys {
        "vim.diagnostic.severity.ERROR" = "󰅚";
        "vim.diagnostic.severity.WARN" = "󰀪";
        "vim.diagnostic.severity.INFO" = "󰌶";
        "vim.diagnostic.severity.HINT" = "";
      };
    };
  };
}
