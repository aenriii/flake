{ config, pkgs, lib, ... }:

let 
  use = config.hostprofile.kernel.flavor == "lts";
in {
  # description = "lts.nix - lts kernel.";
  boot.kernelPackages = lib.mkIf use pkgs.linuxPackages_lts;
}