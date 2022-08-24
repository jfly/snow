{ ... }: {
  programs.home-manager.enable = true;
  home.stateVersion = "22.05";
  home.username = "jeremy";
  home.homeDirectory = "/home/jeremy";

  home.file.".zshrc".source = ../dotfiles/homies/zshrc;
}
