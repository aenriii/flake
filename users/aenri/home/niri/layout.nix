{ ... }:
{
  gaps = 16;
  center-focused-column = "never";
  preset-column-widths = [
    { proportion = 1. / 3.; }
    { proportion = 1. / 2.; }
    { proportion = 2. / 3.; }
  ];
  focus-ring = {
    enable = true;
    width = 3;
    active.color = "#ac0089";
    inactive.color = "#505050";
  };
  shadow = {
    enable = true;
    softness = 30;
    spread = 5;
    offset = {
      x = 0;
      y = 5;
    };
    color = "#0007";
  };
}