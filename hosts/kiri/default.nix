{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../../modules/persistence/impermanence.nix
    ../../modules/hostprofile.nix
    # kernel
    ../../modules/kernel/default.nix
    ../../modules/network/firewall.nix
    ../../users/kiri/default.nix
  ];
  hostprofile = {
    hasTPM2 = false;
    noCompromises = false; # someday i will have a cpu good enough to survive noCompromises = true;
    kernelFlavor = "hardened"; # import & build the latest linux-hardened release.
    kernelConfig = "hardened"; # use a custom hardened config.
  };
  networking.hostName = "kiri";
  time.timeZone = "America/Indiana/Indianapolis";
  system.stateVersion = "25.05";
  nix.settings.allowed-users = [ "kiri" "@wheel" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.tailscale.enable = true;

  # allow tailscale traffic and ssh over tailnet
  networking.firewall = {
    allowedUDPPorts = [ config.services.tailscale.port ];
    trustedInterfaces = [ "tailscale0" ];
  };
}
