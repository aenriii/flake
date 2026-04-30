{ config, lib, pkgs, ... }:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
    allowPing = false;
    logRefusedConnections = true;
    # fix for discord voice failing to connect
    extraInputRules = ''
      ip protocol icmp icmp type destination-unreachable accept
      ip6 nexthdr icmpv6 icmpv6 type { destination-unreachable, packet-too-big } accept
    '';
  };
  networking.nftables.enable = true;
  # services.opensnitch.enable = true; # todo: add opensnitch-ui to all hosts
}