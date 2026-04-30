{ config, pkgs, lib, niri-flake, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    # hardened kernel
    ../../modules/kernel/hardened.nix
    # boot stages / security
    ../../modules/boot/lanzaboote.nix
    ../../modules/boot/luks/paranoid.nix
    # persistence
    ../../modules/persistence/impermanence.nix
    # network security
    ../../modules/network/firewall.nix
    ../../modules/network/dns.nix
    ../../modules/network/tailscale.nix
    # external devices
    ../../modules/security/usb-killswitch.nix
    ../../modules/security/usbguard.nix
    # security
    ../../modules/security/sops.nix
    ../../modules/security/apparmor/hardened.nix
    ../../modules/security/hardened.nix
    ../../modules/security/fido2.nix
    # specializations
    ../../modules/specializations/gaming.nix
    # users
    ../../users/aenri/default.nix
    ../../users/gamer/default.nix
    # desktop
    ../../modules/desktop/niri.nix
  ];
  
  nixpkgs.overlays = [ niri-flake.overlays.niri ];
  nix.settings.allowed-users = [ "aenri" ];
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 30d"; };
  nix.optimise.automatic = true;
  
  networking.hostName = "deaddove";
  time.timeZone = "America/Indiana/Indianapolis";
  system.stateVersion = "25.05";
  # home-manager.sharedModules = [ niri-flake.homeModules.niri ];
  home-manager.users.aenri = {
    programs.niri.settings = {
      outputs = {
        
      };
    };
  };
}
