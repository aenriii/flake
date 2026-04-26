{ config, pkgs, lib, ... }:
let
  pythonEnv = pkgs.python3.withPackages (ps: with ps; [
    numpy
    faiss
    sentence-transformers
  ]);
in
{
  home.username = "kiri";
  home.homeDirectory = "/home/kiri";
  home.stateVersion = "25.05";

  home.packages = [
    pythonEnv
    pkgs.git
    pkgs.nodejs_22
  ];

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
  };
}
