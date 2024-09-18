{ lib, ... }:

let
  inherit (lib.nixvim) mkRaw;
  notesDir = "~/sync/scratch/jfly/notes/";
in
{
  # Don't automatically fold a file when first opening it. I prefer to start
  # with everything visible.
  opts.foldenable = false;

  # https://bitcrowd.dev/folding-sections-of-markdown-in-vim
  globals.markdown_folding = 1;

  keymaps = [
    {
      options.desc = "Note New: start a new note";
      key = "<leader>nn";
      mode = "n";
      action = mkRaw ''
        function()
          local date = os.date('%Y-%m-%d')
          local file_path = '${notesDir}' .. date .. '-.md'
          vim.fn.feedkeys(":e " .. file_path)

          local left = vim.api.nvim_replace_termcodes('<Left><Left><Left>', true, true, true)

          vim.api.nvim_feedkeys(left, 'n', false)
        end
      '';
    }
    {
      options.desc = "Note List: open a list of notes";
      key = "<leader>nl";
      mode = "n";
      action = mkRaw ''
        function()
          vim.g.netrw_sort_by = 'time'
          vim.g.netrw_sort_direction = 'reversed'
          vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]

          local notes_dir = vim.fn.expand('${notesDir}')
          vim.cmd.edit(notes_dir)
        end
      '';
    }
    {
      options.desc = "Note Header: create a new header";
      key = "<leader>nh";
      mode = "n";
      action = mkRaw ''
        function()
          local heading = os.date('# %Y-%m-%d %H:%M %z: ')

          vim.api.nvim_put({heading}, 'l', true, true)
          vim.cmd('norm! k')
          vim.cmd("startinsert!")
        end
      '';
    }
  ];
}
