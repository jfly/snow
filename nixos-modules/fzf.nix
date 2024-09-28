let
  # By default, ripgrep (rg) honors .gitignore folders, but it still looks in
  # `.git` folders. This gets it to also ignore those `.git` folders.
  # https://github.com/BurntSushi/ripgrep/discussions/1578
  fzfCommand = "rg --files --hidden --glob '!.git'";
in
{
  programs.fzf = {
    fuzzyCompletion = true;
    keybindings = true;
  };

  environment.variables = {
    FZF_DEFAULT_COMMAND = fzfCommand;
    FZF_CTRL_T_COMMAND = fzfCommand;
  };
}
