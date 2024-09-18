{ pkgs, ... }:

{
  extraPlugins = with pkgs.vimPlugins; [
    editorconfig-vim
  ];

  opts = {
    # Show existing tab with 4 spaces width.
    tabstop = 4;
    # When indenting with '>', use 4 spaces width.
    shiftwidth = 4;
    # On pressing tab, insert 4 spaces.
    expandtab = true;
  };
}
