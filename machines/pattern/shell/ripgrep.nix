{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.ripgrep ];
  environment.variables.RIPGREP_CONFIG_PATH = pkgs.writeTextFile {
    name = "ripgreprc";
    text = ''
      # Search dotfiles and recurse into dotdirs.
      --hidden

      # By default, ripgrep (rg) honors .gitignore folders, but it still looks in
      # `.git` folders. This gets it to also ignore those `.git` folders.
      # https://github.com/BurntSushi/ripgrep/discussions/1578
      --glob=!.git
    '';
  };
}
