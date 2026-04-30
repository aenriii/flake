{ config, lib, pkgs, ... }:
{
  programs.yubikey-touch-detector.enable = true;
  environment.systemPackages = with pkgs; [ yubikey-manager yubioath-flutter ];
}