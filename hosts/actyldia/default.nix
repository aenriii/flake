{ config, pkgs, lib, niri-flake, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../../modules/hostprofile.nix
    # kernel
    ../../modules/kernel/default.nix
    # boot stages / security
    ../../modules/boot/luks/normal.nix
    # persistence
    ../../modules/persistence/impermanence.nix
    # network security
    ../../modules/network/firewall.nix
    ../../modules/network/dns.nix
    ../../modules/network/tailscale.nix
    # security
    ../../modules/security/sops.nix
    ../../modules/security/apparmor/hardened.nix
    ../../modules/security/hardened.nix
    # users
    ../../users/aenri/default.nix
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

  # home-manager.sharedModules = [ niri-flake.homeModules.niri ];
  networking.hostName = "actyldia";
  time.timeZone = "America/Indiana/Indianapolis";
  system.stateVersion = "25.05";
  
  
  # no need for lanzaboote in a vm
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
