{ config, lib, pkgs, ... }:
{
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "25%";
  fileSystems."/proc" = {
    device = "proc";
    fsType = "proc";
    options = [ "defaults" "hidepid=2" "gid=proc" ];
    neededForBoot = true;
  };
}