{ config, lib, ... }:
let
  cfg = config.hostprofile;
in
{
  imports = [
    ./kernel/default.nix
    ./boot/lanzaboote.nix
    ./boot/luks/paranoid.nix
    ./desktop/niri.nix
    ./desktop/plasma6.nix
    ./specializations/fortress.nix
  ];

  options.hostprofile = {
    boot = {
      luks = lib.mkOption {
        type = lib.types.enum [ "basic" "paranoid" ];
        default = "paranoid";
        description = ''
          The LUKS encryption mode to use. Can be 'basic' or 'paranoid'.

          'basic' puts the boot partition unencrypted, and the header alongside
          the encrypted data.

          'paranoid' puts the header seperately on an encrypted partition of an
          external drive.
        '';
      };
      lanzaboote = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to use lanzaboote for secure boot.
        '';
      };
      tpm2Bind = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Adds additional security by binding the LUKS2 hybrid enrollment to
          relevant TPM2 PCRs. This requires a TPM2 device to be available. This
          also makes your device unbootable if you do not enroll a Shamir secret
          recovery key and your device loses access to the TPM2 device.
        '';
      };
    };
    kernel = {
      flavor = lib.mkOption {
        type = lib.types.enum [ "common" "hardened" "lts" ];
        default = "common";
        description = ''
          The kernel flavor to use. Can be 'common', 'hardened', or 'lts'.
        '';
      };
      config = lib.mkOption {
        type = lib.types.enum [ "hardened" "fortress" ];
        default = "hardened";
        description = ''
          The kernel configuration to use. Can be 'hardened', or 'fortress'.

          'hardened' is a daily-drivable secure configuration. it is the 
          default configuration, and incurs a 5-15% performance penalty 
          primarily on high-memory workloads due to slab_debug=ZP and 
          spec_store_bypass_disable=on. these penalties are universal to all
          pyria users, as it is assessed that the performance impact is
          more than acceptable for the security benefits.

          'fortress' is a highly secure configuration, but is not recommended
          for most users. expect a 50-75% performance penalty, as SMT is
          disabled and slab_debug=FZP is enabled.
        '';
      };
    };
    desktops = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "niri" "plasma6" "xfce" "gnome" ]);
      default = [ "plasma6" ];
      description = ''
        The desktop environment(s) to install. Can include 'niri', 'plasma6', 'xfce', or 'gnome'.
      '';
    };
    specializations = lib.mkOption {
      type = lib.types.listOf (lib.types.enum [ "fortress" ]);
      default = [];
      description = ''
        The specializations to install. Can include 'fortress'.
      '';
    };
  };

  config = {
    pyria.lanzaboote.enable = cfg.boot.lanzaboote;
    pyria.paranoidLuks.enable = cfg.boot.luks == "paranoid";
    pyria.desktop.niri.enable = builtins.elem "niri" cfg.desktops;
    pyria.desktop.plasma6.enable = builtins.elem "plasma6" cfg.desktops;
    pyria.specializations.fortress.enable = builtins.elem "fortress" cfg.specializations;
  };
}
