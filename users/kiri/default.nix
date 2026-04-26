{ config, pkgs, ... }:
{
  imports = [
    ../common/default.nix
  ];

  users.users.kiri = {
    isNormalUser = true;
    extraGroups = [ ];
    shell = pkgs.zsh;
  };

  home-manager.users.kiri = import ./home.nix;

  environment.persistence."/persist".directories = [
    { directory = "/home/kiri"; user = "kiri"; group = "users"; mode = "0700"; }
  ];
  
}
