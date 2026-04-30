{ lib, pkgs, ... }:
{
  specialisation.gaming.configuration = {
    imports = [
      ../desktop/plasma6.nix
    ];
    # use default kernel flavor and loose config for gaming
    # this enables what steam & proton-battleye need to run.
    config.hostprofile = {
      kernelFlavor = "default";
      kernelConfig = "loose";
    };
    # disable niri & greetd in this specialisation so plasma6 + sddm can run
    programs.niri.enable = lib.mkForce false;
    services.greetd.enable = lib.mkForce false;
    # also disable gnome xdg portal since plasma uses kde portal
    xdg.portal.extraPortals = lib.mkForce (with pkgs; [ kdePackages.xdg-desktop-portal-kde ]);
  };
}