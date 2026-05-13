{ config, pkgs, lib, ... }:

let 
  use = config.hostprofile.kernel.flavor == "common";
in {
  # description = "default.nix - mainline kernel.";
  boot.kernelPackages = lib.mkIf use pkgs.linuxPackages_latest;
}