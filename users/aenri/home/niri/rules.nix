{ ... }:
[
  {
    matches = [{
      app-id = "firefox";
      title = "^Picture-in-Picture";
    }];
    open-floating = true;
  }
  {
    geometry-corner-radius = {
      bottom-left = 5.0;
      bottom-right = 5.0;
      top-left = 5.0;
      top-right = 5.0;
    };
    clip-to-geometry = true;
  }
  {
    matches = [{
      app-id = "steam";
    }];
    excludes = [{
      title = "^[Ss]team$";
    }];
    open-floating = true;
  }
  {
    matches = [{
      app-id = "steam";
      title = "^notificationtoasts_\\d+_desktop$";
    }];
    default-floating-position = {
      x = 10;
      y = 10;
      relative-to = "bottom-right";
    };
    open-focused = false;
  }
]