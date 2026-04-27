{ pkgs, ... }:
{
  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = [ "vfat" "ext4" "btrfs" ];
  
  # workaround for nixpkgs#368856: FIDO2 token enumeration in initrd
  # requires the systemd fido_id udev helper and rules to be present
  boot.initrd.services.udev.packages = [
    (pkgs.runCommand "udev-fido2-rules" {} ''
      mkdir -p $out/lib/udev/rules.d/
      cp ${pkgs.systemd}/lib/udev/rules.d/60-fido-id.rules \
         $out/lib/udev/rules.d/60-fido-id.rules
    '')
  ];
  boot.initrd.systemd.storePaths = [
    "${pkgs.systemd}/lib/udev/fido_id"
  ];
  
  boot.initrd.luks.devices."luks-header" = {
    device = "/dev/disk/by-partlabel/header";
    crypttabExtraOpts = [
      "fido2-device=auto"
      "token-timeout=0"
    ];
  };
  fileSystems."/boot/luks-header".neededForBoot = true;
  boot.initrd.luks.devices."nixos" = {
    device = "/dev/disk/by-partlabel/nixos";
    header = "/boot/luks-header/nixos.img";
    crypttabExtraOpts = [
      "fido2-device=auto"
      "token-timeout=0"
    ];
  };
}