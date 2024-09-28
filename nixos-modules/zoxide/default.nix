{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.zoxide ];

  # https://github.com/ajeetdsouza/zoxide#installation
  programs.zsh.interactiveShellInit =
    # bash
    ''
      eval "$(zoxide init zsh)"
    '';

  # https://github.com/ajeetdsouza/zoxide#installation
  programs.fish.interactiveShellInit =
    # fish
    ''
      zoxide init fish | source
    '';
}
