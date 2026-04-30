{ config, lib, pkgs, ... }:
{
  services.resolved = {
    settings.Resolve = {
      DNSOverTLS = "true";
      DNSSEC = "true";
      Domains = [ "~." ];
      FallbackDNS = [ "9.9.9.9#dns.quad9.net" ];
    };
  };
  networking.networkmanager.dns = "systemd-resolved";
}
