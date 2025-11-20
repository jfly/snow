{ pkgs, ... }:

{
  # Always use light "dim" colorscheme, which is designed to leave all
  # the careful color choosing up to our terminal emulator itself.
  # See https://jeffkreeftmeijer.com/vim-16-color/ for details.
  extraPlugins = with pkgs.vimPlugins; [
    (vim-dim.overrideAttrs {
      patches = [
        (pkgs.fetchpatch {
          name = "Add support for neovim >= 0.10.0";
          url = "https://github.com/jeffkreeftmeijer/vim-dim/compare/8320a40f12cf89295afc4f13eb10159f29c43777...1.2.0.diff";
          hash = "sha256-hynkSvfSa7zPWa59Z7yj4gbVlaOgOCnmodPbj/rFImM=";
        })
      ];
    })
  ];
  colorscheme = "dim";

  # This is supposed to default to false, but it sometimes gets set to
  # true (?), so I'm opting to explicitly disable it.
  opts.termguicolors = false;

  # We have to explicitly set background=light here because vim is
  # smart enough to detect the *actual* configured colors and set this
  # automatically. See https://github.com/neovim/neovim/pull/9509.
  # Unfortunately, it's not smart enough to re-detect this if you
  # change your terminal's colorscheme after starting vim, and I don't
  # even want to think about what it would take to get that to work
  # over ssh...
  opts.background = "light";

  # Not exactly colorscheme, but this feels like the most relevant place.
  plugins.web-devicons.enable = true;
}
