{ lib, ... }:

let
  inherit (lib.nixvim) mkRaw;
in
{
  plugins.fzf-lua = {
    enable = true;

    settings.winopts = {
      split = "belowright new";
      height = 0.4;
      preview.hidden = "hidden";
    };
    keymaps = {
      "<C-p>" = "files";
      "<leader>b" = "buffers";
    };
  };

  # Search case insensitive, unless there's a capital letter (smartcase).
  opts = {
    smartcase = true;
    ignorecase = true;
  };

  extraConfigLuaPre = ''
    local SearchDirection = {
      FORWARD = '/',
      BACKWARD = '?',
    }

    local function searchBuf(word, opts)
      local direction = opts.direction or SearchDirection.FORWARD
      local case_sensitivity_prefix = ({
        [true] = "\\C",
        [false] = "\\c",
        default = "",
      })[opts.case_sensitive or "default"]

      vim.fn.feedkeys(direction .. case_sensitivity_prefix .. "\\<" .. word .. "\\>\r", 'n')
    end
  '';

  keymaps = [
    # Override * and # so they do case sensitive searches (regardless of if
    # smartcase is enabled). Huge thanks to Justin Jaffray for writing the
    # original Vimscript for this, which I ported to Lua.
    {
      key = "*";
      options.desc = "Search forwards for word under cursor (case sensitive)";
      action = mkRaw ''
        function()
          local word = vim.fn.expand("<cword>")
          searchBuf(word, {
            direction = SearchDirection.FORWARD,
            case_sensitive = true,
          })
        end
      '';
    }
    {
      key = "#";
      options.desc = "Search backwards for word under cursor (case sensitive)";
      action = mkRaw ''
        function()
          local word = vim.fn.expand("<cword>")
          searchBuf(word, {
            direction = SearchDirection.BACKWARD,
            case_sensitive = true,
          })
        end
      '';
    }
    {
      key = "<leader>*";
      options.desc = "Search project for word under cursor";
      action = mkRaw ''
        function()
          local word = vim.fn.expand("<cword>")
          require('fzf-lua').grep { search = word }
        end
      '';
    }
    {
      key = "<C-CR>";
      options.desc = "Do a project-wide search (instead of a buffer search)";
      mode = "c";
      action = mkRaw ''
        function()
          local cmd_type = vim.fn.getcmdtype()
          local is_searching = cmd_type == "/" or cmd_type == "?"

          if is_searching then
            local enter = vim.api.nvim_replace_termcodes('<CR>', true, true, true)
            vim.api.nvim_feedkeys(enter, 'n', false)
          end

          local search = vim.fn.getcmdline()
          if search == "" then
            search = vim.fn.expand("<cword>")
          end

          local escape = vim.api.nvim_replace_termcodes('<Esc>', true, true, true)
          vim.api.nvim_feedkeys(escape, 'n', false)

          vim.schedule(function()
            local search = vim.fn.getreg('/')
            require('fzf-lua').grep { search = search }
          end)
        end
      '';
    }
    {
      key = "]q";
      options.desc = "Select next item in the quickfix list";
      action = ":cnext<CR>";
    }
    {
      key = "[q";
      options.desc = "Select previous item in the quickfix list";
      action = ":cprevious<CR>";
    }
    # TBH, this isn't really searching or fzf related, but it kind of makes
    # sense to have this live near fzf's buffer switching keymap.
    {
      key = "<leader><leader>";
      options.desc = "Switch to the previous buffer";
      action = "<c-^>";
    }
  ];
}
