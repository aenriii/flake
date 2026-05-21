{ config, pkgs, lib, niri-flake, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../../modules/hostprofile.nix
    ../../modules/common.nix
    ../../modules/network/tailscale.nix
    ../../users/aenri/default.nix
  ];
  
  hostprofile = {
    boot = {
      luks = "paranoid";
      lanzaboote = true;
      tpm2Bind = false; # dont have tpm2 :(
    };
    kernel = {
      flavor = "hardened";
      config = "hardened";
    };
    desktops = [ "niri" "plasma6" "xfce" ];
    specializations = [ "fortress" ];
  };
  
  nixpkgs.config.allowUnfree = true;
  nix.settings.allowed-users = [ "aenri" ];
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 30d"; };
  nix.optimise.automatic = true;
  
  
  networking.hostName = "deaddove";
  time.timeZone = "America/Indiana/Indianapolis";
  system.stateVersion = "25.11";
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.aenri = {
    programs.niri.settings = {
      outputs = {};
    };
  };
}
