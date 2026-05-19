{
  plugins.fzf-lua.enable = true;

  keymaps = [
    {
      key = "<C-S-p>";
      options.desc = "Resume FZF session";
      action = ":FzfLua resume<CR>";
    }
  ];
}
