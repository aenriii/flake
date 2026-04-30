{ config, lib, pkgs, ... }:
{
  services.tailscale = {
    enable = true;
    extraUpFlags = [ 
      "--accept-dns=false"
      "--exit-node-allow-lan-access=false"
    ];
  };
  networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
  # only allow tailscale's dns to be used for *.ts.net addresses.
  systemd.network.networks."50-tailscale" = {
    matchConfig.Name = "tailscale0";
    networkConfig = {
      DNS = [ "100.100.100.100" ];
      Domains = "~ts.net";
      LLMNR = false;
      MulticastDNS = false;
      MTUBytes = "1280";
    };
  };

}