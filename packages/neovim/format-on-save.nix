{ pkgs, lib, ... }:

let
  inherit (lib.nixvim) mkRaw;
in
{
  # Format on save.
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
  # '';
  plugins.none-ls.settings.enableLspFormat = true;
  plugins.none-ls.sources.formatting.nix_flake_fmt.enable = true;
  plugins.none-ls.package = pkgs.vimPlugins.none-ls-nvim.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      (pkgs.fetchpatch {
        name = "fix(nix_flake_fmt): handle flakes with a `formatter` package";
        url = "https://github.com/nvimtools/none-ls.nvim/pull/272.patch";
        hash = "sha256-lvxffTBIVVs14OBi2zKDd/aSwGrpPgQkxqM0TPU5A6U=";
      })
      (pkgs.fetchpatch {
        name = "fix (client.lua): fixes issue";
        url = "https://github.com/nvimtools/none-ls.nvim/commit/3ac8b7b6d6177f31e425aa5aa3c6f07d4b0e788b.patch";
        hash = "sha256-sac+h6g3itqbQ95WJoenIysa2/3sOxPsGzV0T9GBPe0=";
      })
      (pkgs.fetchpatch {
        name = "chore: rework nix_flake_fmt to use the new nix formatter subcommand";
        url = "https://github.com/nvimtools/none-ls.nvim/commit/6ff3ab9c6b333edcc89f25a3b9332fbdb8543fa9.patch";
        hash = "sha256-zZ/zailZY8l9xkxQlM67Tuog9RGoE7sTiCAq63kYb7w=";
      })
      (pkgs.fetchpatch {
        name = "fix(nix_flake_fmt): ask the user if the project is trusted";
        url = "https://github.com/nvimtools/none-ls.nvim/pull/280.diff";
        hash = "sha256-HkvIM4HdOzOJtC5lzvb275LSql5I0T+DWTIaJ8v/Qpg=";
      })
    ];
  });
}
