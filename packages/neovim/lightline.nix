{
  plugins.lualine = {
    enable = true;
    settings = {
      options = {
        theme = "16color";
      };

      tabline = {
        lualine_a = [ "buffers" ];
        lualine_z = [ "tabs" ];
      };
    };
  };
}
