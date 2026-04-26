{ config, pkgs, lib, ... }:
{
  disko.devices = {
    disk = {
      ssd = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            nixos = {
              size = "100%";
              content = {
                type = "luks";
                name = "nixos";
                settings = {
                  allowDiscards = false;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-L" "nixos" "-f" ];
                  subvolumes = {
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" "nodev" "nosuid" ];
                    };
                    "@persist" = {
                      mountpoint = "/persist";
                      mountOptions = [ "compress=zstd" "noatime" "nodev" "nosuid" ];
                    };
                    "@games" = {
                      mountpoint = "/home/gamer";
                      mountOptions = [ "compress=zstd" "noatime" "nodev" "nosuid" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
      usb = {
        type = "disk";
        device = "/dev/sdb"; # change later!
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            header = {
              size = "512M";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/boot/luks-header";
                extraArgs = [ "-L" "NIXHEADER" ];
              };
            };
          };
        };
      };
    };
    
    nodev = {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [ "defaults" "size=2G" "mode=0755" ];
      };
    };
  };
  
}