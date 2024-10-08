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
    local snow_search = {}

    do
      local Direction = {
        FORWARD = '/',
        BACKWARD = '?',
      }

      local function search_buf(word, opts)
        local direction = opts.direction or Direction.FORWARD
        local case_sensitivity_prefix = ({
          [true] = "\\C",
          [false] = "\\c",
          default = "",
        })[opts.case_sensitive or "default"]

        vim.fn.feedkeys(direction .. case_sensitivity_prefix .. "\\<" .. word .. "\\>\r", 'n')
      end

      local function get_selection()
        local chunks = vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'), { type = vim.fn.mode() })
        return table.concat(chunks, [[\n]])
      end

      local function get_search_term()
        local mode = vim.fn.mode()

        if mode == "n" then
          return vim.fn.expand("<cword>")
        elseif mode == "v" then
          -- Note: this does not do the escaping that upstream does [0]
          -- Maybe upstream would be interested in making some of that functionality available publicly..
          --
          -- [0]: https://github.com/neovim/neovim/blob/v0.10.1/runtime/lua/vim/_defaults.lua#L35-L48
          return get_selection()
        else
          assert(false, "unrecognized mode " .. mode)
        end
      end

      snow_search.Direction = Direction
      snow_search.search_buf = search_buf
      snow_search.get_search_term = get_search_term
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
          local word = snow_search.get_search_term()
          snow_search.search_buf(word, {
            direction = snow_search.Direction.FORWARD,
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
          local word = snow_search.get_search_term()
          snow_search.search_buf(word, {
            direction = snow_search.Direction.BACKWARD,
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
          local word = snow_search.get_search_term()
          require('fzf-lua').grep { search = word }
        end
      '';
    }
    {
      # TODO: change back to `<C-CR>` once Fish supports CSI u. See
      # hosts/pattern/homies/config/with-alacritty/default.conf for details.
      # key = "<C-CR>";
      key = "<C-Q>";
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
    # TBH, this isn't really searching or fzf related, but it kind of makes
    # sense to have this live near fzf's buffer switching keymap.
    {
      key = "<leader><leader>";
      options.desc = "Switch to the previous buffer";
      action = "<c-^>";
    }
  ];
}
