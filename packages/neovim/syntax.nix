{
  plugins.treesitter = {
    enable = true;
    settings.highlight.enable = true;
  };

  filetype.pattern = {
    ".*%.yaml%.aged" = "yaml";
  };
}
