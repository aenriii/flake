{ config, lib, pkgs, ... }:
{
  services.resolved = {
    enable = true;
    dnssec = "true";
    dnsovertls = "true";
    domains = [ "~." ];
    fallbackDns = [ "9.9.9.9#dns.quad9.net" ];
  };
  networking.networkmanager.dns = "systemd-resolved";

}
