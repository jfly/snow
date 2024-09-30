{ lib, pkgs, ... }:

let
  inherit (lib.nixvim) mkRaw;
in
{
  plugins.fugitive.enable = true;
  plugins.fzf-lua.enable = true;
  plugins.fzf-lua.package = pkgs.vimPlugins.fzf-lua.overrideAttrs {
    patches = [
      # Fixes <https://github.com/ibhagwan/fzf-lua/issues/1462>
      (pkgs.fetchurl {
        url = "https://github.com/ibhagwan/fzf-lua/commit/d76cc35a2945beb4d916050a8ad34b7daf1b4054.patch";
        hash = "sha256-RepcJrwR4mYxszShoc83Z37QByOu5qrNoN5Ww9bHECo=";
      })
    ];
  };

  extraPlugins = with pkgs.vimPlugins; [
    vim-rhubarb
  ];

  keymaps = [
    {
      key = "<leader>gb";
      options.desc = "Git blame";
      action = ":Git blame<CR>";
    }
    {
      key = "<leader>gs";
      options.desc = "Git status";
      action = mkRaw "require('fzf-lua').git_status";
    }
  ];

  autoCmd = [
    {
      desc = "When creating a new file in a Nix Flake, create it with --intent-to-add";
      event = "BufWritePre";
      callback = mkRaw ''
        function(args)
          local file = args.file

          local function in_git_repo()
            local cp = vim.system({'git', 'rev-parse', '--is-inside-work-tree'}):wait()
            return cp.stdout == "true\n"
          end

          local is_new_file = vim.fn.filereadable(file) == 0

          if is_new_file and in_git_repo() then
            vim.fn.writefile({}, file)
            local cmd = {'git', 'add', '--intent-to-add', file}
            local cp = vim.system(cmd):wait()
            if cp.code ~= 0 then
              vim.notify("Failed to run: " .. table.concat(cmd, " "), vim.log.levels.ERROR)
            else
              vim.notify("Marked new file with git --intent-to-add", vim.log.levels.INFO)
            end
          end
        end
      '';
    }
  ];
}
