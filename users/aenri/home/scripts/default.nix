{ pkgs, lib, ... }:
{
  _module.args.scripts = {
    screenshot = import ./screenshot.nix { inherit pkgs; };
  };
}