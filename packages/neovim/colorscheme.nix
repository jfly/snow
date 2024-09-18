{ pkgs, ... }:

{
  # Always use light "dim" colorscheme, which is designed to leave all
  # the careful color choosing up to our terminal emulator itself.
  # See https://jeffkreeftmeijer.com/vim-16-color/ for details.
  extraPlugins = with pkgs.vimPlugins; [
    (vim-dim.overrideAttrs {
      patches = [
        # I should get rid of this fork. Looks like stuff might be happening over
        # on
        # https://github.com/jeffkreeftmeijer/vim-dim/issues/12#issuecomment-2302537189?
        # I'm subscribed to the relevant issue.
        (pkgs.fetchpatch {
          name = "latest inkscape/silhouette unstable";
          # https://github.com/jeffkreeftmeijer/vim-dim/compare/main...jfly:vim-dim:nvim-tweaks.patch
          url = "https://github.com/jeffkreeftmeijer/vim-dim/compare/main...jfly:vim-dim:23124b9d4da1e1ecbfdb145714a4f0759bdde8d1.patch";
          hash = "sha256-J/rL6oDxs8ySxKDK2rlgcBxtNWCc+Jf6BdypFFJMAuc=";
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
