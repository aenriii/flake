{ config, pkgs, lib, ... }:

let 
  use = (!config.hostprofile.noCompromises) && config.hostprofile.kernelFlavor == "default";
in {
  # description = "default.nix - mainline kernel.";
  boot.kernelPackages = lib.mkIf use pkgs.linuxPackages_latest;
}