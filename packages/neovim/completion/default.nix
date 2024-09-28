{ lib, pkgs, ... }:
let
  conflictMarker = "<" + "<<";
  snippetsByFiletype = {
    "python" = {
      "__main__ boilerplate" = {
        "prefix" = "main";
        "body" = [
          "def main():"
          "\t\${1:pass}"
          ""
          "if __name__ == \"__main__\":"
          "\tmain()"
        ];
      };
      "breakpoint" = {
        "prefix" = "b";
        "body" = [ "breakpoint() # ${conflictMarker}" ];
      };
    };
  };
  snippetsPkg = pkgs.symlinkJoin {
    name = "snippets";
    paths = lib.mapAttrsToList (
      filetype: snippets: pkgs.writeTextDir "${filetype}.json" (lib.strings.toJSON snippets)
    ) snippetsByFiletype;
  };
in

{
  imports = [
    ./override-keyword-completion-with-cmp-buffer.nix
  ];

  # Snippets
  plugins.nvim-snippets = {
    enable = true;
    settings.create_cmp_source = true;
    settings.search_paths = [ "${snippetsPkg}" ];
  };

  # Autocompletion
  plugins.cmp = {
    enable = true;
    autoEnableSources = true;
    settings = {
      sources = [
        {
          name = "nvim_lsp";
          group_index = 1;
        }
        {
          # This source is provided by `nvim-snippets`.
          name = "snippets";
          group_index = 1;
        }
        {
          name = "path";
          group_index = 2;
        }
      ];

      # This is pretty slick: it shows grayed out "ghost text" in the buffer
      # illustrating what would happen if you accept the currently selected
      # completion.
      experimental.ghost_text = true;

      mapping = {
        # `behavior = cmp.SelectBehavior.Select` ensures that pressing `<Esc>`
        # will return the buffer to its original, unmodified state. See the
        # remapping of `<Esc>` above for an analogous thing we do for Neovim's builtin keyword completion.
        # I see nvim-cmp has support for an
        "<C-p>" = "cmp.mapping(cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }), {'i', 's'})";
        "<C-n>" = "cmp.mapping(cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }), {'i', 's'})";

        "<C-e>" = "cmp.mapping.abort()";
        "<Esc>" = ''
          function(fallback)
            if require('cmp').abort() then
              vim.schedule(function()
                vim.api.nvim_input('<Esc>')
              end)
            else
              fallback()
            end
          end
        '';
        "<CR>" = "cmp.mapping.confirm({ select = false })";
        # TODO: change back to `<C-CR>` once Fish supports CSI u. See
        # hosts/pattern/homies/config/with-alacritty/default.conf for details.
        "<C-Q>" = "cmp.mapping.confirm({ select = true })";
      };
    };
  };
}
