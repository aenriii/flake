{ pkgs, lib, ... }:
{
  nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
    nixd
    nil
    claude-code
    rustup
  ];
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = true;
    withRuby = true;
  };
}