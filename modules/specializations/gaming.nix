{ config, pkgs, ... }:
{
  specialisation.gaming.configuration = {
    imports = [ ../kernel/gaming.nix ../desktop/plasma6.nix ];
  };
}