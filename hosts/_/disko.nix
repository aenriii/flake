{ ... }:
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
                    #<insert-point>
                  };
                };
              };
            };
          };
        };
      };
      usb = {
        type = "disk";
        device = "%boot-device%";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "3G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "noexec" "nosuid" "nodev" "umask=0077" ];
              };
            };
            header = {
              size = "1G";
              content = {
                type = "luks";
                name = "bootlock";
                settings = {
                  allowDiscards = false;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/boot/lock";
                  extraArgs = [ "-L" "NIXHEADER" ];
                };
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