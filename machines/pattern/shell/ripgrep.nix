{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.ripgrep ];
  environment.variables.RIPGREP_CONFIG_PATH = pkgs.writeTextFile {
    name = "ripgreprc";
    text = ''
      # Search dotfiles and recurse into dotdirs.
      --hidden
    '';
  };
}
