{ config, lib, pkgs, ... }:
{
  services.resolved = {
    settings.Resolve = {
      DNSOverTLS = "yes";
      DNSSEC = "true";
      Domains = [ "~." ];
      DNS = [ "9.9.9.9#dns.quad9.net" "149.112.112.112#dns.quad9.net" ];
      FallbackDNS = [ "9.9.9.9#dns.quad9.net" ];
    };
  };
  networking.networkmanager.dns = "systemd-resolved";
}
