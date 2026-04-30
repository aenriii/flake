{ config, lib, pkgs, ... }:

{
  options.hostprofile = {
    hasTPM2 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether the system has a TPM2 chip.";
    };
    noCompromises = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Performs multiple additional security hardening measures, 
        such as disabling hyperthreading and enabling slab_debug=F.
        
        Also implicitly sets kernelFlavor to "hardened" and kernelConfig to "lockdown".
      '';
    };
    kernelFlavor = lib.mkOption {
      type = lib.types.enum [ "default" "hardened" ];
      default = "default" ;
      description = "The default base kernel to use. Can be 'default' or 'hardened'. Selecting 'hardened' compiles the latest release of github:anthraxx/linux-hardened, which may lag behind official kernel releases.";
    };
    kernelConfig = lib.mkOption {
      type = lib.types.enum [ "common" "hardened" "fortress" "loose" ];
      default = "hardened";
      description = ''
        The kernel configuration to use. Can be 'common', 'hardened', 'fortress', or 'loose'.
      '';
    };
  };
}