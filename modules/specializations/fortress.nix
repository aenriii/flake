{ config, pkgs, lib, ... }:

{
  specialisation.fortress.config = {
    config.hostprofile = {
      kernelFlavor = "hardened";
      kernelConfig = "fortress";
    };
  };
}