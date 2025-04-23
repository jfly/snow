{
  # Don't automatically fold a file when first opening it. I prefer to start
  # with everything visible.
  opts.foldenable = false;

  # https://bitcrowd.dev/folding-sections-of-markdown-in-vim
  globals.markdown_folding = 1;

  plugins.markdown-preview.enable = true;
}
