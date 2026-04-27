{ config, lib, pkgs, ... }:
{
  services.pcscd.enable = true;
  programs.yubikey-touch-detector.enable = true;
  environment.systemPackages = with pkgs; [ yubikey-manager yubioath-flutter ];
}