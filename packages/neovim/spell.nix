{ lib, ... }:

let
  inherit (lib.nixvim) mkRaw;
in
{
  opts.spell = true;

  keymaps = [
    {
      key = "<leader>s";
      options.desc = "Toggle spelling";
      action = mkRaw ''
        function()
          vim.opt.spell = not(vim.opt.spell:get())
        end
      '';
    }
  ];
}
