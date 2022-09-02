import Data.Map
import Data.List
import System.Exit
import Graphics.X11.ExtraTypes.XF86

import XMonad hiding ( (|||) ) -- don't use the normal ||| operator
import XMonad.Layout.LayoutCombinators -- use the one from LayoutCombinators instead
import XMonad.Config.Desktop
import XMonad.Layout.ToggleLayouts
import XMonad.Layout.ThreeColumns
import XMonad.Actions.CycleWS
import XMonad.Actions.SpawnOn
import XMonad.Layout.NoBorders
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.EwmhDesktops
import XMonad.Util.Run(spawnPipe)
import qualified XMonad.StackSet as W
import qualified XMonad.Util.Hacks as Hacks
import XMonad.Hooks.WindowSwallowing

-- Rebind Mod to the Windows key
myModMask = mod4Mask

myTerminal = "alacritty"
tall = Tall 1 (3/100) (1/2)
threeCol = ThreeCol 1 (3/100) (0.36) -- just enough space for 100 columns wide in vim
myLayout = avoidStruts $ smartBorders $ toggleLayouts Full tall ||| toggleLayouts Full threeCol ||| toggleLayouts Full (Mirror tall)

myBorderWidth = 2

musicWs = "🎵"
videoWs = "📹"
backspaceWs = "⌫"
myWorkspaces = ["`", "wrk", "be", "fe", "test", videoWs, "6", "7", "8", "9", "0", "-", "=", backspaceWs, musicWs]
myWorkspaceKeys = [xK_grave] ++ [xK_1 .. xK_9] ++ [xK_0, xK_minus, xK_equal, xK_BackSpace, xK_m]

workspaceSenders = [ appName =? ("send to " ++ wsName) --> doShift wsName | wsName <- myWorkspaces ]

windowPlacement = composeAll ([
        -- use `xprop` to get window information:
        -- https://wiki.haskell.org/Xmonad/Frequently_asked_questions#A_handy_script_to_print_out_window_information

        className =? "Chromium" <&&> fmap (isInfixOf "Google Play Music") title --> doShift musicWs,
        appName =? "meet.google.com__zhw-huyd-oam" <&&> className =? "Chromium" --> doShift videoWs,

        -- Fix for GIMP windows
        className =? "Gimp" --> doFloat,

        -- Music stuff
        className =? "Mcg" --> doShift musicWs,
        title =? "CoverGrid" --> doShift musicWs,

        appName =? "picker" --> doFloat
    ] ++ workspaceSenders) where role = stringProperty "WM_WINDOW_ROLE"

fullscreenChrome :: X ()
fullscreenChrome = do
    sendMessage ToggleStruts
    spawn "sleep 0.1 && xdotool key --clearmodifiers F11"
    return ()


altMask = mod1Mask
myKeys conf@(XConfig {XMonad.modMask = modMask}) = Data.Map.fromList $
    [ ((modMask .|. shiftMask, xK_c     ), kill) -- %! Close the focused window

    -- move focus up or down the window stack
    , ((modMask,               xK_j     ), windows W.focusDown) -- %! Move focus to the next window
    , ((modMask,               xK_k     ), windows W.focusUp  ) -- %! Move focus to the previous window
    , ((modMask,               xK_m     ), windows W.focusMaster  )
    , ((modMask, xK_n), windows W.focusMaster) -- %! Move focus to the master window

    -- modifying the window order
    , ((modMask .|. shiftMask, xK_j     ), windows W.swapDown  ) -- %! Swap the focused window with the next window
    , ((modMask .|. shiftMask, xK_k     ), windows W.swapUp    ) -- %! Swap the focused window with the previous window
    -- Swap the focused window and the master window The default uses
    -- return, but semicolon is easier to reach =)
    , ((modMask, xK_semicolon), windows W.swapMaster)

    -- resizing the split
    , ((modMask,               xK_h     ), sendMessage Shrink) -- %! Shrink the main area
    , ((modMask,               xK_l     ), sendMessage Expand) -- %! Expand the main area

    -- increase or decrease number of windows in the master area
    , ((modMask              , xK_comma ), sendMessage (IncMasterN 1)) -- %! Increment the number of windows in the master area
    , ((modMask              , xK_period), sendMessage (IncMasterN (-1))) -- %! Deincrement the number of windows in the master area

    -- quit, or restart
    , ((modMask .|. shiftMask, xK_q     ), io (exitWith ExitSuccess)) -- %! Quit xmonad
    , ((modMask              , xK_q     ), sequence_ [
        spawn "@libnotify@/bin/notify-send 'Restarting xmonad'",
        (restart "xmonad" True)
    ])

    -- http://xmonad.org/xmonad-docs/xmonad-contrib/XMonad-Hooks-ManageDocks.html
    , ((modMask, xK_b), sendMessage ToggleStruts)
    , ((modMask, xK_F11), fullscreenChrome)

    -- Launch a terminal
    , ((modMask .|. shiftMask, xK_semicolon), spawn $ "cd $(xcwd); exec " ++ myTerminal)

    -- Toggle layout.
    , ((modMask, xK_space), sendMessage ToggleLayout) -- Note: this doesn't work great with space as meta
    , ((modMask, xK_g), sendMessage ToggleLayout) -- Added as an alternative when using space as meta

    -- Go to next layout.
    , ((modMask, xK_t), sendMessage NextLayout)

    -- Reset to default layout
    , ((modMask .|. shiftMask, xK_g), setLayout $ XMonad.layoutHook conf)

    -- Force window back to tiling mode
    , ((modMask .|. shiftMask, xK_t), withFocused $ windows . W.sink)

    -- Toggle last workspace
    , ((modMask, xK_Tab), toggleWS)

    -- Run demenu2
    , ((modMask, xK_p), spawn "dmenu_run")

    , ((0, xF86XK_AudioMute), spawn "@jvol@/bin/jvol toggle sink")
    , ((0, xF86XK_AudioRaiseVolume), spawn "@jvol@/bin/jvol set sink 5%+")
    , ((0, xF86XK_AudioLowerVolume), spawn "@jvol@/bin/jvol set sink 5%-")
    , ((0, xF86XK_AudioMicMute), spawn "@jvol@/bin/jvol toggle source")
    , ((0, xF86XK_AudioPlay), spawn "mpc toggle")
    , ((0, xF86XK_AudioPrev), spawn "mpc prev")
    , ((0, xF86XK_AudioNext), spawn "mpc next")

    , ((0, xF86XK_MonBrightnessDown), spawn "@jbright@/bin/jbright set 5%-")
    , ((0, xF86XK_MonBrightnessUp), spawn "@jbright@/bin/jbright set 5%+")
    , ((shiftMask, xK_F4), spawn "colorscheme clear current")
    , ((shiftMask, xK_F5), spawn "colorscheme cycle current dark light")
    -- Create our own play/pause and prev/next buttons.
    , ((modMask, xK_s), spawn "xdotool key --clearmodifiers XF86AudioPlay")
    , ((modMask, xK_d), spawn "xdotool key --clearmodifiers XF86AudioNext")
    , ((modMask .|. shiftMask, xK_d), spawn "xdotool key --clearmodifiers XF86AudioPrev")

    -- Prompt the user for an area of the screen
    , ((0, xK_Print), spawn "@jscrot@/bin/jscrot --select")
    , ((controlMask, xK_Print), spawn "@jscrot@/bin/jscrot --video")
    , ((shiftMask, xK_Print), spawn "@jscrot@/bin/jscrot")

    , ((controlMask .|. altMask, xK_Left), spawn "xrandr -o right && @setbg@/bin/setbg")
    , ((controlMask .|. altMask, xK_Right), spawn "xrandr -o left && @setbg@/bin/setbg")
    , ((controlMask .|. altMask, xK_Down), spawn "xrandr -o normal && @setbg@/bin/setbg")
    , ((controlMask .|. altMask, xK_Up), spawn "xrandr -o inverted && @setbg@/bin/setbg")

    -- Dunst shortcuts
    , ((controlMask, xK_space), spawn "dunstctl close")
    , ((controlMask, xK_grave), spawn "dunstctl history-pop")
    , ((controlMask .|. shiftMask, xK_period), spawn "dunstctl context")

    , ((modMask, xK_a), spawn "systemctl restart --user autoperipherals")
    ] ++
    -- mod-[1..9] %! Switch to workspace N
    -- mod-shift-[1..9] %! Move client to workspace N
    [((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip myWorkspaces myWorkspaceKeys
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)]]

isNotInfixOf a b = not (a `isInfixOf` b)

main = do
    dirs <- getDirectories
    let conf = docks $ ewmh desktopConfig {
        manageHook = manageDocks <+> manageSpawn <+> windowPlacement <+> manageHook desktopConfig,
        handleEventHook = handleEventHook def <+> Hacks.windowedFullscreenFixEventHook <+> swallowEventHook (className =? "Alacritty" <&&> fmap ( "xmonad-no-swallow" `isNotInfixOf`) title) (return True),
        layoutHook = myLayout,
        modMask = myModMask,
        XMonad.terminal = myTerminal,
        XMonad.borderWidth = myBorderWidth,
        XMonad.keys = myKeys,
        workspaces = myWorkspaces
    } in launch conf dirs
