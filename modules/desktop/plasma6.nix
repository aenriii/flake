{ config, lib, ... }:
{
  imports = [ ./common.nix ];

  options.pyria.desktop.plasma6.enable = lib.mkEnableOption "plasma6 desktop";

  config = lib.mkIf config.pyria.desktop.plasma6.enable {
    services.desktopManager.plasma6.enable = true;
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.greetd.enable = lib.mkForce false;
  };
}
