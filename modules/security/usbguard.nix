{ config, lib, pkgs, ... }:
{
  services.usbguard = {
    enable = true;
    rules = ''
      allow with-interface equals { 03:00:00 03:01:00 03:02:00 }
      block
    '';
  };
}