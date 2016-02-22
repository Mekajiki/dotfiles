import XMonad
import XMonad.Hooks.SetWMName
import XMonad.Layout.Minimize
import XMonad.Hooks.DynamicLog
import XMonad.Util.CustomKeys
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO

main = do
  xmonad =<< xmobar myConfig

myConfig = defaultConfig
    { startupHook = setWMName "LG3D"
    , modMask = mod4Mask
    } `additionalKeys`
    [ ((mod1Mask, xK_space), spawn "ibus engine xkb:us::eng")
    , ((mod1Mask .|. shiftMask , xK_space), spawn "ibus engine mozc-jp")
    ]
