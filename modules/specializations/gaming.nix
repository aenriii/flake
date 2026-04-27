{ lib, pkgs, ... }:
{
  specialisation.gaming.configuration = {
    imports = [
      ../kernel/gaming.nix
      ../desktop/plasma6.nix
    ];
    # disable niri & greetd in this specialisation so plasma6 + sddm can run
    programs.niri.enable = lib.mkForce false;
    services.greetd.enable = lib.mkForce false;
    # also disable gnome xdg portal since plasma uses kde portal
    xdg.portal.extraPortals = lib.mkForce (with pkgs; [ kdePackages.xdg-desktop-portal-kde ]);
  };
}