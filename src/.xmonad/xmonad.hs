import XMonad
import XMonad.Hooks.SetWMName
import XMonad.Layout.Minimize
import XMonad.Hooks.DynamicLog
import XMonad.Util.CustomKeys
import XMonad.Util.Run(spawnPipe)
import XMonad.Util.EZConfig(additionalKeys)
import System.IO
import XMonad.Config.Gnome

main = do
  xmonad =<< xmobar myConfig

myConfig = defaultConfig
    { startupHook = setWMName "LG3D"
    , modMask = mod4Mask
    }
