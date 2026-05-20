{ config, pkgs, lib, ... }:
{
  home.username = "aenri";
  home.homeDirectory = "/home/aenri";
  home.stateVersion = "25.11";
  home.sessionVariables = {
    EDITOR = "nvim";
  };
  home.file.".face" = ./.face.png;
  imports = [
    ./home/zsh.nix
  ];
  
}
