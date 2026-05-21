{ config, lib, scripts, ... }:
  let noctalia = argv: builtins.concatLists [[ "qs" "-c" "noctalia-shell" "ipc" "call" ] argv];
in
{
  "Mod+Return".action.spawn = "alacritty";
  "Mod+D".action.spawn = noctalia ["launcher" "toggle"];
  "Mod+ALT+L".action.spawn = noctalia ["lockScreen" "lock"];
  "Mod+Shift+Q".action.spawn = noctalia ["sessionMenu" "toggle"];

  "XF86AudioRaiseVolume" = {
    action.spawn = noctalia ["volume" "increase"];
    allow-when-locked = true;
  };
  "XF86AudioLowerVolume" = {
    action.spawn = noctalia ["volume" "decrease"];
    allow-when-locked = true;
  };
  "XF86AudioMute" = {
    action.spawn = noctalia ["volume" "muteOutput"];
    allow-when-locked = true;
  };
  "XF86AudioMicMute" = {
    action.spawn = noctalia ["volume" "muteInput"];
    allow-when-locked = true;
  };
  "XF86AudioNext" = {
    action.spawn = noctalia ["media" "next"];
    allow-when-locked = true;
  };
  "XF86AudioPrev" = {
    action.spawn = noctalia ["media" "previous"];
    allow-when-locked = true;
  };
  "XF86AudioPlay" = {
    action.spawn = noctalia ["media" "playPause"];
    allow-when-locked = true;
  };
  "XF86AudioPause" = {
    action.spawn = noctalia ["media" "playPause"];
    allow-when-locked = true;
  };

  "XF86MonBrightnessUp" = {
    action.spawn = noctalia ["brightness" "increase"];
    allow-when-locked = true;
  };
  "XF86MonBrightnessDown" = {
    action.spawn = noctalia ["brightness" "decrease"];
    allow-when-locked = true;
  };


  "Mod+Q".action.close-window = [ ];
  "Mod+Left".action.focus-column-left = [ ];
  "Mod+H".action.focus-column-left = [ ];
  "Mod+Right".action.focus-column-right = [ ];
  "Mod+L".action.focus-column-right = [ ];
  "Mod+Up".action.focus-window-up = [ ];
  "Mod+K".action.focus-window-up = [ ];
  "Mod+Down".action.focus-window-down = [ ];
  "Mod+J".action.focus-window-down = [ ];
  
  "Mod+CTRL+Left".action.move-column-left = [ ];
  "Mod+CTRL+H".action.move-column-left = [ ];
  "Mod+CTRL+Right".action.move-column-right = [ ];
  "Mod+CTRL+L".action.move-column-right = [ ];
  "Mod+CTRL+UP".action.move-window-up = [ ];
  "Mod+CTRL+K".action.move-window-up = [ ];
  "Mod+CTRL+Down".action.move-window-down = [ ];
  "Mod+CTRL+J".action.move-window-down = [ ];

  "Mod+Home".action.focus-column-first = [ ];
  "Mod+End".action.focus-column-last = [ ];
  "Mod+CTRL+Home".action.move-column-to-first = [ ];
  "Mod+CTRL+End".action.move-column-to-last = [ ];
  
  "Mod+Shift+Left".action.focus-monitor-left = [ ];
  "Mod+Shift+Right".action.focus-monitor-right = [ ];
  "Mod+Shift+UP".action.focus-monitor-up = [ ];
  "Mod+Shift+Down".action.focus-monitor-down = [ ];
  
  "Mod+Shift+CTRL+Left".action.move-column-to-monitor-left = [ ];
  "Mod+Shift+CTRL+Right".action.move-column-to-monitor-right = [ ];
  "Mod+Shift+CTRL+UP".action.move-column-to-monitor-up = [ ];
  "Mod+Shift+CTRL+Down".action.move-column-to-monitor-down = [ ];
  
  # Window Movement and Focus
  "Mod+WheelScrollDown" = { 
    action.focus-workspace-down = [ ];
    cooldown-ms=150;
  };
  "Mod+WheelScrollUp" = { 
    action.focus-workspace-up = [ ];
    cooldown-ms=150;
  };
  "Mod+CTRL+WheelScrollDown" = { 
    action.move-column-to-workspace-down = [ ];
    cooldown-ms=150;
  };
  "Mod+CTRL+WheelScrollUp" = { 
    action.move-column-to-workspace-up = [ ];
    cooldown-ms=150;
  };
  "Mod+WheelScrollRight".action.focus-column-right = [ ];
  "Mod+WheelScrollLeft".action.focus-column-left = [ ];
  "Mod+CTRL+WheelScrollRight".action.move-column-right = [ ];
  "Mod+CTRL+WheelScrollLeft".action.move-column-left = [ ];
  
  "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
  "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];
  "Mod+CTRL+Shift+WheelScrollDown".action.move-column-right = [ ];
  "Mod+CTRL+Shift+WheelScrollUp".action.move-column-left = [ ];
  
  "Mod+1".action.focus-workspace = 1;
  "Mod+2".action.focus-workspace = 2;
  "Mod+3".action.focus-workspace = 3;
  "Mod+4".action.focus-workspace = 4;
  "Mod+5".action.focus-workspace = 5;
  "Mod+6".action.focus-workspace = 6;
  "Mod+7".action.focus-workspace = 7;
  "Mod+8".action.focus-workspace = 8;
  "Mod+9".action.focus-workspace = 9;
  
  "Mod+CTRL+1".action.move-column-to-workspace = 1;
  "Mod+CTRL+2".action.move-column-to-workspace = 2;
  "Mod+CTRL+3".action.move-column-to-workspace = 3;
  "Mod+CTRL+4".action.move-column-to-workspace = 4;
  "Mod+CTRL+5".action.move-column-to-workspace = 5;
  "Mod+CTRL+6".action.move-column-to-workspace = 6;
  "Mod+CTRL+7".action.move-column-to-workspace = 7;
  "Mod+CTRL+8".action.move-column-to-workspace = 8;
  "Mod+CTRL+9".action.move-column-to-workspace = 9;
  
  "Mod+TAB".action.focus-workspace-previous = [ ];

  #  Layout Controls 
  "Mod+CTRL+F".action.expand-column-to-available-width = [ ];
  "Mod+C".action.center-column = [ ];
  "Mod+CTRL+C".action.center-visible-columns = [ ];
  "Mod+Minus".action.set-column-width = "-10%";
  "Mod+Equal".action.set-column-width = "+10%";
  "Mod+Shift+Minus".action.set-window-height = "-10%";
  "Mod+Shift+Equal".action.set-window-height = "+10%";
  
  #  Modes 
  "Mod+T".action.toggle-window-floating = [ ];
  "Mod+F".action.fullscreen-window = [ ];
  "Mod+W".action.toggle-column-tabbed-display = [ ];
  
  #  Screenshots 
  "PRINT".action.spawn = [ (lib.getExe scripts.screenshot) ];
  #  Emergency Escape Key 
  # Use this when a fullscreen app blocks your keybinds.
  # It disables any active keyboard shortcut inhibitor, restoring control.
  "Mod+ESCAPE" = {
    action.toggle-keyboard-shortcuts-inhibit = [ ];
    allow-inhibiting = false;
  };

  # Exit / Power 
  "CTRL+ALT+Delete".action.quit = [ ];
  "Mod+Shift+P".action.power-off-monitors = [ ];
  "Mod+O" = {
    action.toggle-overview = [ ];
    repeat = false;
  };
}