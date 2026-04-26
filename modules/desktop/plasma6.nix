{ config, pkgs, ... }:
{
  imports = [ ./common.nix ];
  services.desktopManager.plasma6.enable = true;
  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.greetd.enable = lib.mkForce false;
}