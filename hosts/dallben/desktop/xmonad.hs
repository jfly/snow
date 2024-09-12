import XMonad
import XMonad.Config.Desktop
import XMonad.Layout.NoBorders
import XMonad.Hooks.EwmhDesktops


myLayout = smartBorders $ Full ||| tiled
  where
     -- default tiling algorithm partitions the screen into two panes
     tiled   = Tall nmaster delta ratio
     -- The default number of windows in the master pane
     nmaster = 1
     -- Default proportion of screen occupied by master pane
     ratio   = 1/2
     -- Percent of screen to increment by when resizing panes
     delta   = 3/100


main = xmonad $ ewmh desktopConfig
    { terminal    = "xterm"
    , modMask     = mod4Mask
    , layoutHook  = myLayout
    }
