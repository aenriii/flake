{ config, lib, scripts, ... }:
{
  "Mod+Return".action.spawn = "alacritty";
  "Mod+D".action.spawn = config.noctalia.ipc-sh + ["launcher" "toggle"];
  "Mod+ALT+L".action.spawn = config.noctalia.ipc-sh + ["lockScreen" "lock"];
  "Mod+Shift+Q".action.spawn = config.noctalia.ipc-sh + ["sessionMenu" "toggle"];

  "XF86AudioRaiseVolume" = {
    action.spawn = config.noctalia.ipc-sh + ["volume" "increase"];
    allow-when-locked = true;
  };
  "XF86AudioLowerVolume" = {
    action.spawn = config.noctalia.ipc-sh + ["volume" "decrease"];
    allow-when-locked = true;
  };
  "XF86AudioMute" = {
    action.spawn = config.noctalia.ipc-sh + ["volume" "muteOutput"];
    allow-when-locked = true;
  };
  "XF86AudioMicMute" = {
    action.spawn = config.noctalia.ipc-sh + ["volume" "muteInput"];
    allow-when-locked = true;
  };
  "XF86AudioNext" = {
    action.spawn = config.noctalia.ipc-sh + ["media" "next"];
    allow-when-locked = true;
  };
  "XF86AudioPrev" = {
    action.spawn = config.noctalia.ipc-sh + ["media" "previous"];
    allow-when-locked = true;
  };
  "XF86AudioPlay" = {
    action.spawn = config.noctalia.ipc-sh + ["media" "playPause"];
    allow-when-locked = true;
  };
  "XF86AudioPause" = {
    action.spawn = config.noctalia.ipc-sh + ["media" "playPause"];
    allow-when-locked = true;
  };

  "XF86MonBrightnessUp" = {
    action.spawn = config.noctalia.ipc-sh + ["brightness" "increase"];
    allow-when-locked = true;
  };
  "XF86MonBrightnessDown" = {
    action.spawn = config.noctalia.ipc-sh + ["brightness" "decrease"];
    allow-when-locked = true;
  };


  "Mod+Q".action.close-window = true;
  "Mod+Left".action.focus-column-left = true;
  "Mod+H".action.focus-column-left = true;
  "Mod+Right".action.focus-column-right = true;
  "Mod+L".action.focus-column-right = true;
  "Mod+Up".action.focus-window-up = true;
  "Mod+K".action.focus-window-up = true;
  "Mod+Down".action.focus-window-down = true;
  "Mod+J".action.focus-window-down = true;
  
  "Mod+CTRL+Left".action.move-column-left = true;
  "Mod+CTRL+H".action.move-column-left = true;
  "Mod+CTRL+Right".action.move-column-right = true;
  "Mod+CTRL+L".action.move-column-right = true;
  "Mod+CTRL+UP".action.move-window-up = true;
  "Mod+CTRL+K".action.move-window-up = true;
  "Mod+CTRL+Down".action.move-window-down = true;
  "Mod+CTRL+J".action.move-window-down = true;

  "Mod+Home".action.focus-column-first = true;
  "Mod+End".action.focus-column-last = true;
  "Mod+CTRL+Home".action.move-column-to-first = true;
  "Mod+CTRL+End".action.move-column-to-last = true;
  
  "Mod+Shift+Left".action.focus-monitor-left = true;
  "Mod+Shift+Right".action.focus-monitor-right = true;
  "Mod+Shift+UP".action.focus-monitor-up = true;
  "Mod+Shift+Down".action.focus-monitor-down = true;
  
  "Mod+Shift+CTRL+Left".action.move-column-to-monitor-left = true;
  "Mod+Shift+CTRL+Right".action.move-column-to-monitor-right = true;
  "Mod+Shift+CTRL+UP".action.move-column-to-monitor-up = true;
  "Mod+Shift+CTRL+Down".action.move-column-to-monitor-down = true;
  
  # Window Movement and Focus
  "Mod+WheelScrollDown" = { 
    action.focus-workspace-down = true;
    cooldown-ms=150;
  };
  "Mod+WheelScrollUp" = { 
    action.focus-workspace-up = true;
    cooldown-ms=150;
  };
  "Mod+CTRL+WheelScrollDown" = { 
    action.move-column-to-workspace-down = true;
    cooldown-ms=150;
  };
  "Mod+CTRL+WheelScrollUp" = { 
    action.move-column-to-workspace-up = true;
    cooldown-ms=150;
  };
  "Mod+WheelScrollRight".action.focus-column-right = true;
  "Mod+WheelScrollLeft".action.focus-column-left = true;
  "Mod+CTRL+WheelScrollRight".action.move-column-right = true;
  "Mod+CTRL+WheelScrollLeft".action.move-column-left = true;
  
  "Mod+Shift+WheelScrollDown".action.focus-column-right = true;
  "Mod+Shift+WheelScrollUp".action.focus-column-left = true;
  "Mod+CTRL+Shift+WheelScrollDown".action.move-column-right = true;
  "Mod+CTRL+Shift+WheelScrollUp".action.move-column-left = true;
  
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
  
  "Mod+TAB".action.focus-workspace-previous = true;

  #  Layout Controls 
  "Mod+CTRL+F".action.expand-column-to-available-width = true;
  "Mod+C".action.center-column = true;
  "Mod+CTRL+C".action.center-visible-columns = true;
  "Mod+Minus".action.set-column-width = "-10%";
  "Mod+Equal".action.set-column-width = "+10%";
  "Mod+Shift+Minus".action.set-window-height = "-10%";
  "Mod+Shift+Equal".action.set-window-height = "+10%";
  
  #  Modes 
  "Mod+T".action.toggle-window-floating = true;
  "Mod+F".action.fullscreen-window = true;
  "Mod+W".action.toggle-column-tabbed-display = true;
  
  #  Screenshots 
  "PRINT".action.spawn = [ (lib.getExe scripts.screenshot) ];
  #  Emergency Escape Key 
  # Use this when a fullscreen app blocks your keybinds.
  # It disables any active keyboard shortcut inhibitor, restoring control.
  "Mod+ESCAPE" = {
    action.toggle-keyboard-shortcuts-inhibit = true;
    allow-inhibiting = false;
  };

  # Exit / Power 
  "CTRL+ALT+Delete".action.quit = true;
  "Mod+Shift+P".action.power-off-monitors = true;
  "Mod+O" = {
    action.toggle-overview = true;
    repeat = false;
  };
}