{ pkgs, lib, ... }:

let
  inherit (lib.nixvim) mkRaw;
in
{
  # Format on save.
  plugins.lspconfig.enable = true; # lsp-format depends on lspconfig
  plugins.lsp-format.enable = true;
  plugins.lsp-format.package = pkgs.vimPlugins.lsp-format-nvim.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      (pkgs.fetchpatch {
        name = "Switch to non-deprecated client methods";
        url = "https://github.com/lukas-reineke/lsp-format.nvim/pull/97.patch";
        hash = "sha256-7P2YOE8cM6QHnKYRBC3t4aJkox7xobyiHkvPEp53WQA=";
      })
    ];
  });
  # By default, lsp-format is configured to try to format with *all*
  # attached LSPs. I don't want that to happen: if I'm hacking on some
  # random repository, I don't want to suddenly reformat all their code.
  # So, we disable all LSP servers here.
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
  # plugins.none-ls.settings.debug = true;
  # extraConfigLuaPre = ''
  #   vim.opt.rtp:prepend("/home/jeremy/src/github.com/nvimtools/none-ls.nvim")
  #   vim.opt.rtp:prepend("/home/jeremy/src/github.com/lukas-reineke/lsp-format.nvim")
  # '';
  plugins.none-ls.enableLspFormat = true;
  plugins.none-ls.sources.formatting.nix_flake_fmt.enable = true;
  plugins.none-ls.package = pkgs.vimPlugins.none-ls-nvim.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      (pkgs.fetchpatch {
        name = "fix(nix_flake_fmt): ask the user if the project is trusted";
        url = "https://github.com/nvimtools/none-ls.nvim/pull/280.diff";
        hash = "sha256-HkvIM4HdOzOJtC5lzvb275LSql5I0T+DWTIaJ8v/Qpg=";
      })
      (pkgs.fetchpatch {
        name = "fix: don't assume `flake_ref` exists";
        url = "https://github.com/nvimtools/none-ls.nvim/pull/286.diff";
        hash = "sha256-mQ1yLLrdALUvHZbTsQ/sCGVimsY5lLgnnLIewyJcVgg=";
      })
    ];
  });
}
