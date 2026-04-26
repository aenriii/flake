{ config, pkgs, ... }:

{
  imports = [ 
    ../common/default.nix
    ../../modules/desktop/niri.nix
  ];
  users.users.aenri = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };
  home-manager.users.aenri = import ./home.nix;
  environment.persistence."/persist".directories = [
    { directory = "/home/aenri"; user = "aenri"; group = "users"; mode = "0700"; }
  ];
}