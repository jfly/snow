{ pkgs, lib, ... }:

let
  inherit (pkgs)
    fetchurl
    vimPlugins
    ;
  inherit (lib.nixvim) mkRaw;
in
{
  # Format on save.
  plugins.lsp-format.enable = true;
  # By default, lsp-format is configured to try to format with *all*
  # attached LSPs. I don't want that to happen: if I'm hacking on some
  # random repository, I don't want to suddently reformat all their code.
  # So, we disable all lsp servers here.
  plugins.lsp-format.lspServersToEnable = "none";

  keymaps = [
    {
      key = "<leader>ta";
      options.desc = "Toggle autoformatting";
      action = mkRaw ''
        function()
          local lsp_format = require("lsp-format")

          lsp_format.disabled = not lsp_format.disabled

          local message
          if lsp_format.disabled then
            message = "Autoformatting is off"
          else
            message = "Autoformatting is on"
          end
          vim.notify(message, vim.log.levels.INFO)
        end
      '';
    }
  ];

  # Instead, configure none-ls to be the only formatter used by lsp-format.
  plugins.none-ls.enable = true;
  plugins.none-ls.settings.enableLspFormat = true;
  plugins.none-ls.settings.sources = [ ''require("null-ls").builtins.formatting.nix_flake_fmt'' ];

  # Apply my patches to none-ls that add the `nix_flake_fmt` formatter.
  # Bonus: if I get this upstreamed, then nixvim should generate a nice nixified
  # option I can use above instead.
  plugins.none-ls.package = (
    vimPlugins.none-ls-nvim.overrideAttrs {
      patches = [
        # TODO: try to upstream this to none-js. Currently blocked by a
        # treefmt "issue" that I'm chatting with the maintainer (@brianmcgee)
        # about.
        (fetchurl {
          url = "https://github.com/nvimtools/none-ls.nvim/compare/main...jfly:none-ls.nvim:add-nix-fmt.patch";
          hash = "sha256-fishasjC3umtDCNR3w3ua8eauBra1xB75uRsTb0XnEE=";
        })
      ];
    }
  );
}
