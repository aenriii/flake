{ inputs, config, pkgs, lib, nixgl, ... }:
{
  home.username = "aenri";
  home.homeDirectory = "/home/aenri";
  home.stateVersion = "25.11";
  home.sessionVariables = {
    EDITOR = "nvim";
    NIX_BUILD_SHELL = "zsh";
  };
  imports = [
    ../../nix/home-modules/pyria-sudo.nix
    ./home/scripts/default.nix
    ./home/zsh.nix
    ./home/dev.nix
    ./home/zed.nix
    ./home/niri.nix
    ./home/gaming/steam.nix 
  ];
  home.packages = [
    pkgs.zed-editor
    pkgs.helium
    pkgs.signal-desktop
    pkgs.legcord
    pkgs.paru
  ];
  home.file = {
    ".face".source = ./assets/.face.png;
  };

  programs.pyria-sudo = {
    enable = true;
    aliasSudo = true;
    shadowSudo = true;
  };
}
