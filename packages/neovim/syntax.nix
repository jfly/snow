{
  plugins.treesitter = {
    enable = true;
    settings = {
      indent.enable = true;
      highlight.enable = true;
    };
  };

  filetype.pattern = {
    ".*%.yaml%.aged" = "yaml";
  };
}
