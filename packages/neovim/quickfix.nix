{
  config,
  lib,
  ...
}:

let
  inherit (lib) types;
  inherit (lib.nixvim) mkRaw;
  inherit (lib.options) mkOption;

  cfg = config.snow.quickfix;
in
{
  options = {
    snow.quickfix.toggle_key = mkOption {
      description = "The key to toggle visibility of the quickfix list.";
      type = types.str;
      default = null;
    };
    snow.quickfix.pre_open = mkOption {
      description = "Optional Lua function to run right before opening the quickfix list. Useful to populate the quickfix list.";
      type = types.str;
      default = "nil";
    };
  };

  config = {
    plugins.sticky-quickfix.enable = true;

    extraConfigLuaPre = ''
      local snow_qf = {}

      do
        snow_qf.is_open = function()
          local is_open = false
          for _, win in pairs(vim.fn.getwininfo()) do
            if win["quickfix"] == 1 then
              is_open = true
            end
          end

          return is_open
        end

        snow_qf.toggle = function()
          if snow_qf.is_open() then
            vim.cmd "cclose"
          else
            if snow_qf.pre_open then
              snow_qf.pre_open()
            end

            vim.cmd "copen"
          end
        end

        snow_qf.jump = function(steps, opts)
          local force_qf = opts and opts.qf

          if force_qf or snow_qf.is_open() then
            local qf_count = vim.tbl_count(vim.fn.getqflist())

            if qf_count == 0 then
              return
            end

            local pos_1_indexed = vim.fn.getqflist({ idx = 0 }).idx
            local pos_0_indexed = pos_1_indexed - 1
            local next_pos_0_indexed = (pos_0_indexed + steps) % qf_count
            local next_pos_1_indexed = next_pos_0_indexed + 1

            vim.cmd {
              cmd = "cc",
              count = next_pos_1_indexed,
            }
          else
            if steps > 0 then
              vim.api.nvim_feedkeys(steps .. 'n', 'n', false)
            else
              vim.api.nvim_feedkeys(-steps .. 'N', 'n', false)
            end
          end
        end

        snow_qf.next = function(opts)
          local steps = vim.v.count
          if steps == 0 then
            steps = 1
          end

          snow_qf.jump(steps, opts)
        end

        snow_qf.prev = function(opts)
          local steps = -vim.v.count
          if steps == 0 then
            steps = -1
          end

          snow_qf.jump(steps, opts)
        end
      end
    '';

    keymaps = [
      {
        key = cfg.toggle_key;
        options.desc = "Toggle quickfix list";
        action = mkRaw ''snow_qf.toggle'';
      }
      {
        key = "n";
        options.desc = "Search forwards, or navigate to next quickfix if the quickfix window is open";
        action = mkRaw ''snow_qf.next'';
      }
      {
        key = "N";
        options.desc = "Search backwards, or navigate to prev quickfix if the quickfix window is open";
        action = mkRaw ''snow_qf.prev'';
      }
      {
        key = "]q";
        options.desc = "Select next item in the quickfix list";
        action = mkRaw ''
          function()
            snow_qf.next({qf = true })
          end
        '';
      }
      {
        key = "[q";
        options.desc = "Select previous item in the quickfix list";
        action = mkRaw ''
          function()
            snow_qf.prev({qf = true })
          end
        '';
      }
    ];
  };
}
