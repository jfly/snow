{
  systemd.user.targets = {
    # This `xmonad` target just exists as a workaround for
    # https://github.com/xmonad/xmonad/issues/422.
    # See `shared/xmonad/xmonad.hs` for where this target gets triggered.
    "xmonad" = {
      enable = true;
      partOf = [ "graphical-session.target" ];
    };
  };
}
