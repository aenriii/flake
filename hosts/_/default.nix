{ config, pkgs, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../../modules/hostprofile.nix
  ];
  hostprofile = {
    boot.luks = "<luks>";
    boot.lanzaboote = <lanzaboote>;
    kernel.flavor = "<kernelFlavor>";
    kernel.config = "<kernelConfig>";
    desktops = [ <desktops> ];
    users = {
      <user> = {
        shell = "<shell>";
        useDefaultDotfiles = <useDefaultDotfiles>;
      };
    };
  };

  nix.settings.allowed-users = [ <user> ];
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 30d"; };
  nix.optimise.automatic = true;

  networking.hostName = "<hostname>";
  time.timeZone = "<timeZone>";
  system.stateVersion = "25.11";
}
