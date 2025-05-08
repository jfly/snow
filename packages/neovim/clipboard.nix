{
  # Use OSC 52 specifically when ssh-ing somewhere.
  # Trick from https://github.com/neovim/neovim/discussions/28010
  extraConfigLuaPost = ''
    -- Use the unnamed (default) register for pasting, because terminal
    -- emulators (understandably) refuse to paste when OSC 52 asks for it.
    local function paste()
      return {
        vim.split(vim.fn.getreg(""), "\n"),
        vim.fn.getregtype(""),
      }
    end

    if vim.env.SSH_TTY then
      vim.g.clipboard = {
        name = 'OSC 52 (copy only)',
        copy = {
          ['+'] = require('vim.ui.clipboard.osc52').copy('+'),
          ['*'] = require('vim.ui.clipboard.osc52').copy('*'),
        },
        paste = {
          ['+'] = paste,
          ['*'] = paste,
        },
      }
    end
  '';

  keymaps = [
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
  ];
}
