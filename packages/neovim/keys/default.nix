{ lib, pkgs, ... }:

let
  inherit (lib.nixvim) mkRaw;
in
{
  plugins.which-key.enable = true;

  imports = [
    ./format-on-save.nix
  ];

  globals.mapleader = " ";

  # Disable mouse (neovim enables it by default).
  opts.mouse = "";

  extraPlugins = with pkgs.vimPlugins; [
    vim-rsi # readline shortcuts in useful places
  ];

  plugins.treesitter.settings.incremental_selection = {
    enable = true;
    keymaps = {
      init_selection = "<CR>";
      node_incremental = "<CR>";
      node_decremental = "<BS>";
    };
  };

  keymaps = [
    # Remap `gf` to actually do `gF`. `gF` better: it can understand line
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
          local current_file = vim.fn.expand('%:p')
          local cwd = vim.fn.fnamemodify(current_file, ':h')
          local target_absolute = vim.fn.resolve(cwd .. '/' .. target_path)
          local target_relative_cwd = vim.fn.fnamemodify(target_absolute, ':.')

          vim.cmd('edit ' .. vim.fn.fnameescape(target_relative_cwd))
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
    # Easier copying/pasting with system clipboard.
    {
      key = "<leader>y";
      action = ''"+y'';
    }
    {
      key = "<leader>p";
      action = ''"+p'';
    }
    {
      key = "<leader>P";
      action = ''"+P'';
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

  # Toggle a list of diagnostics.
  snow.diagnostics.toggle_list_key = "<leader>q";

  # Pop up the diagnostics window automatically when jumpin.
  diagnostics.jump.float = true;

  plugins.lsp.keymaps = {
    # vim.diagnostic.<action> mappings.
    diagnostic = {
      "<leader>e" = "open_float";
    };

    # vim.lsb.buf.<action> mappings.
    lspBuf = {
      "gd" = "definition";
      "gD" = "references";
      "gt" = "type_definition";
      "gi" = "implementation";
      "<leader>rn" = "rename";
    };

    extra = [
      # Show workspace symbols
      {
        key = "<leader>fs";
        action = mkRaw ''require("fzf-lua").lsp_workspace_symbols'';
      }
      {
        # This is down here rather than up in `lsbBuf` because this should run
        # in normal *and* insert mode.
        key = "<leader>f";
        action = mkRaw "vim.lsp.buf.code_action";
      }
    ];
  };
}