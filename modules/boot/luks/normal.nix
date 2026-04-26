{ config, pkgs, lib, ... }:
{
  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = [ "btrfs" ];
  boot.initrd.luks.devices."nixos" = {
    device = "/dev/disk/by-label/nixos";
  };
}
