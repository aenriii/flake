{ config, lib, pkgs, ... }:
{
  imports = [ ./common.nix ];

  options.pyria.desktop.niri.enable = lib.mkEnableOption "niri wayland compositor";

  config = lib.mkIf config.pyria.desktop.niri.enable {
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
        };
      };
    };
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
      config.common.default = "*";
    };
    programs.niri.enable = true;
    security.polkit.enable = true;
    security.pam.services.waylock = { };
  };
}
