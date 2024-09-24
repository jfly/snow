{
  # Default indentation rules.
  opts = {
    # Show existing tab with 4 spaces width.
    tabstop = 4;
    # When indenting with '>', use 4 spaces width.
    shiftwidth = 4;
    # On pressing tab, insert 4 spaces.
    expandtab = true;
  };

  # Neovim has [Editorconfig] enabled by default, but when hacking on a random
  # file, it's nice to have heuristics to guess the indentation.
  # [Editorconfig]: https://neovim.io/doc/user/editorconfig.html
  plugins.guess-indent.enable = true;

  # Now that we know the indentation style of this file (see above), use
  # Treesitter for automatic indentation.
  plugins.treesitter.settings.indent.enable = true;
}
