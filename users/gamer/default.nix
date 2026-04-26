{ config, pkgs, ... }:

{
  imports = [ 
    ../common/default.nix
  ];
  users.users.gamer = {
    isNormalUser = true;
    extraGroups = [ "video" "audio" "input" ];
    shell = pkgs.zsh;
  };
}