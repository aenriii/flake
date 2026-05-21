{ ... }:
{
  enable = true;
  workspace-switch = {
    enable = true;
    kind.spring = {
      damping-ratio = 1.0;
      stiffness = 1000;
      epsilon = 0.0001;
    };
  };
  window-open = {
    enable = true;
    kind.easing = {
      duration-ms = 200;
      curve = "ease-out-quad";
    };
  };
  window-close = {
    enable = true;
    kind.easing = {
      duration-ms = 200;
      curve = "ease-out-cubic";
    };
  };
  horizontal-view-movement = {
    enable = true;
    kind.spring = {
      damping-ratio = 1.0;
      stiffness = 900;
      epsilon = 0.0001;
    };
  };
  window-movement = {
    enable = true;
    kind.spring = {
      damping-ratio = 1.0;
      stiffness = 800;
      epsilon = 0.0001;
    };
  };
  window-resize = {
    enable = true;
    kind.spring = {
      damping-ratio = 1.0;
      stiffness = 1000;
      epsilon = 0.0001;
    };
  };
  config-notification-open-close = {
    enable = true;
    kind.spring = {
      damping-ratio = 0.6;
      stiffness = 1200;
      epsilon = 0.001;
    };
  };
  overview-open-close = {
    enable = true;
    kind.spring = {
      damping-ratio = 1.0;
      stiffness = 900;
      epsilon = 0.0001;
    };
  };
}