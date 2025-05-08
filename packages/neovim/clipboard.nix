{
  # Prefer osc52, even if something like `xclip` is installed.
  globals.clipboard = "osc52";

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
