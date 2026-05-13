{ config, lib, pkgs, ... }:
{
  options.pyria.lanzaboote.enable = lib.mkEnableOption "lanzaboote secure boot";

  config = lib.mkIf config.pyria.lanzaboote.enable {
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/persist/secureboot";
    };
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.efi.efiSysMountPoint = "/boot";
    environment.systemPackages = [ pkgs.sbctl ];
  };
}
