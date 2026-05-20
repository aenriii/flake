{ config, ... }:
{
  programs.niri = {
    # enable = true; # do we need this for home-manager with system niri?
    settings = {
      binds = import ./niri/keybinds.nix;
      animations = import ./niri/animations.nix;
    };
  };
}