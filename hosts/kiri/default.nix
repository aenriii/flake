{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware.nix
    ./disko.nix
    ../../modules/hostprofile.nix
    ../../modules/persistence/impermanence.nix
    ../../modules/network/firewall.nix
    ../../users/kiri/default.nix
  ];
  hostprofile = {
    boot = {
      luks = "basic";
    };
    kernel = {
      flavor = "hardened";
      config = "hardened";
    };
    desktops = [];
  };
  networking.hostName = "kiri";
  time.timeZone = "America/Indiana/Indianapolis";
  system.stateVersion = "25.11";
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
