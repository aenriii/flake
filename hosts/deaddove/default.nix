{ config, pkgs, lib, niri-flake, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    # hardware profile
    ../../modules/hostprofile.nix
    # hardened kernel
    ../../modules/kernel/default.nix
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
    ../../modules/specializations/fortress.nix
    # users
    ../../users/aenri/default.nix
    ../../users/gamer/default.nix
    # desktop
    ../../modules/desktop/niri.nix
  ];
  
  hostprofile = {
    hasTPM2 = false;
    noCompromises = false; # someday i will have a cpu good enough to survive noCompromises = true;
    kernelFlavor = "hardened"; # import & build the latest linux-hardened release.
    kernelConfig = "hardened"; # use a custom hardened config.
  };
  
  nixpkgs.overlays = [ niri-flake.overlays.niri ];
  nix.settings.allowed-users = [ "aenri" ];
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 30d"; };
  nix.optimise.automatic = true;
  
  
  networking.hostName = "deaddove";
  time.timeZone = "America/Indiana/Indianapolis";
  system.stateVersion = "25.05";
  home-manager.users.aenri = {
    programs.niri.settings = {
      outputs = {
        
      };
    };
  };
}
