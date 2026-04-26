{ config, lib, pkgs, ... }:
{
  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = [ "vfat" "ext4" "btrfs" ];
  boot.initrd.luks.devices."nixos" = {
    device = "/dev/disk/by-label/nixos";
    header = "/dev/disk/by-label/NIXHEADER";
    crypttabExtraOpts = [
      "fido2-device=auto"
      "token-timeout=0"
    ];
  };
}