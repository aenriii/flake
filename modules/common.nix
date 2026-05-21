{ config, lib, pkgs, ... }:

{
  imports = [
    # persistence
    ./persistence/impermanence.nix
    # network security
    ./network/firewall.nix
    ./network/dns.nix
    ./network/nts.nix
    # external devices
    ./security/usb-killswitch.nix
    ./security/usbguard.nix
    # security
    ./security/sops.nix
    ./security/apparmor.nix
    ./security/hardened.nix
    ./security/fido2.nix
  ];
}