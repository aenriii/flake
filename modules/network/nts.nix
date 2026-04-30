{ ... }:
{
  services.chrony = {
    enable = true;
    servers = [];
    extraConfig = ''
      server time.cloudflare.com iburst nts
      server ntppool1.time.nl iburst nts
      ntsdumpdir /var/lib/chrony
      minsources 2
    '';
  };
  services.timesyncd.enable = false;
}