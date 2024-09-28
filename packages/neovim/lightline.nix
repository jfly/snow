{
  # (This is not a lightline thing, but this file was the closest to the
  # correct place to put this I could find). Update the window title to include
  # the name of the file we're currently editing.
  opts.title = true;
  opts.titlelen = 0;
  opts.titlestring = ''nvim %{expand("%")}'';

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
