{ lib, ... }:

let
  inherit (lib.nixvim) mkRaw;
  notesDir = "~/sync/jfly/notes/";
in
{
  # Sort the notes dir by modification time, newest first.
  extraConfigLuaPre = ''
    vim.api.nvim_create_autocmd('User', {
      pattern = 'DirReadPost',
      callback = function(args)
        local dir = vim.api.nvim_buf_get_name(args.buf)

        if dir ~= vim.fn.expand('${notesDir}') then
          return
        end

        local names = vim.api.nvim_buf_get_lines(args.buf, 0, -1, true)
        local mtime = {} --- @type table<string, integer>
        for _, name in ipairs(names) do
          local stat = vim.uv.fs_stat(vim.fs.joinpath(dir, name))
          mtime[name] = stat and stat.mtime.sec or 0
        end
        table.sort(names, function(a, b)
          return mtime[a] > mtime[b]
        end)
        vim.api.nvim_buf_set_lines(args.buf, 0, -1, true, names)
      end,
    })
  '';

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
          vim.cmd("startinsert!")
        end
      '';
    }
  ];
}
