{
  lib,
  pkgs,
  ...
}:

let
  inherit (lib.nixvim) mkRaw;
in
{
  plugins.which-key.enable = true;

  globals.mapleader = " ";

  # Disable mouse (neovim enables it by default).
  opts.mouse = "";

  extraPlugins = with pkgs.vimPlugins; [
    vim-rsi # Readline shortcuts in useful places.
    treesitter-modules-nvim # Provides tree-sitter based incremental selection.
  ];

  imports = [
    (
      { lib, ... }:
      lib.nixvim.plugins.mkNeovimPlugin {
        name = "treesitter-modules";
        package = "treesitter-modules-nvim";
        maintainers = with lib.maintainers; [ jfly ];
      }
    )
  ];

  plugins.treesitter-modules = {
    enable = true;
    settings.incremental_selection = {
      enable = true;
      keymaps = {
        init_selection = "<CR>";
        node_incremental = "<CR>";
        node_decremental = "<BS>";
      };
      # Workaround for <https://github.com/nvim-treesitter/nvim-treesitter/issues/2634>
      is_supported = mkRaw ''
        function()
          local mode = vim.api.nvim_get_mode().mode
          if mode == "c" then
            return false
          end
          return true
        end
      '';
    };
  };

  keymaps = [
    # Remap `gf` to actually do `gF`. `gF` is better: it can understand line
    # numbers and navigate directly to the line if one is present.
    {
      key = "gf";
      action = "gF";
      options.noremap = true;
    }
    {
      key = "gF";
      action = mkRaw ''
        function()
          local target_path = vim.fn.expand('<cfile>')

          local path
          if target_path:sub(1, 1) == "." then
            local current_file = vim.fn.expand('%:p')
            local cwd = vim.fn.fnamemodify(current_file, ':h')
            local target_absolute = vim.fn.resolve(cwd .. '/' .. target_path)
            path = vim.fn.fnamemodify(target_absolute, ':.')
          else
            path = target_path
          end

          vim.cmd('edit ' .. vim.fn.fnameescape(vim.fn.expand(path)))
        end
      '';
      options.noremap = true;
    }
    # Copy path to current file.
    {
      key = "<leader>cf";
      action = mkRaw ''
        function()
          local current_file = vim.fn.expand('%')
          vim.fn.setreg('+', current_file)
        end
      '';
    }
    # Select whole buffer.
    {
      key = "<leader>a";
      action = "ggVG";
      mode = "n";
    }
    # Save buffer.
    {
      key = "<leader>w";
      action = ":w<CR>";
      mode = "n";
    }

    # Easily move blocks of code around.
    # Copied from
    # https://vim.fandom.com/wiki/Moving_lines_up_or_down#Mappings_to_move_lines
    {
      key = "<C-j>";
      action = ":move .+1<CR>==";
      mode = "n";
    }
    {
      key = "<C-k>";
      action = ":move .-2<CR>==";
      mode = "n";
    }
    {
      key = "<C-j>";
      action = "<Esc>:move .+1<CR>==gi";
      mode = "i";
    }
    {
      key = "<C-k>";
      action = "<Esc>:move .-2<CR>==gi";
      mode = "i";
    }
    {
      key = "<C-j>";
      action = ":move '>+1<CR>gv=gv";
      mode = "v";
    }
    {
      key = "<C-k>";
      action = ":move '<-2<CR>gv=gv";
      mode = "v";
    }
  ];

  # Toggle the quickfix list.
  snow.quickfix.toggle_key = "<leader>q";

  # Pop up the diagnostics window automatically when jumping.
  diagnostic.settings.jump.float = true;

  lsp.keymaps = [
    {
      key = "<leader>e";
      action = mkRaw "vim.diagnostic.open_float";
    }
    {
      key = "gd";
      lspBufAction = "definition";
    }
    {
      key = "gD";
      lspBufAction = "references";
    }
    {
      key = "gt";
      lspBufAction = "type_definition";
    }
    {
      key = "gi";
      lspBufAction = "implementation";
    }
    {
      key = "<leader>rn";
      lspBufAction = "rename";
    }
    {
      key = "<leader>f";
      action = mkRaw "vim.lsp.buf.code_action";
    }
  ];
}
