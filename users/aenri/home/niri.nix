{ config, lib, scripts, ... }:
  let call = lib.flip import {
    inherit lib scripts config;
  };
in
{
  programs.niri = {
    # enable = true; # do we need this for home-manager with system niri?
    settings = {
      binds = call ./niri/keybinds.nix;
      animations = call ./niri/animations.nix;
      outputs = call ./niri/outputs.nix;
      input = call ./niri/input.nix;
      layout = call ./niri/layout.nix;
      window-rules = call ./niri/rules.nix;
      spawn-at-startup = [
        {
          argv = ["qs" "-c" "noctalia-shell"];
        }
      ];
      environment = {
        QT_QPA_PLATFORM = "wayland";
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        QT_QPA_PLATFORMTHEME = "gtk3";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
        XDG_CURRENT_DESKTOP = "niri";
        XDG_SESSION_TYPE = "wayland";
        DISPLAY = ":0";
      };
      prefer-no-csd = true;
      screenshot-path = null;
      cursor = {
        theme = "capitaine-cursors";
        size = 24;
      };
      debug = {
        honor-xdg-activation-with-invalid-serial = [ ];
      };
      hotkey-overlay.skip-at-startup = true;
      # blur = {
      #   passes = 1;
      #   offset = 2.0;
      # };
    };
  };
}