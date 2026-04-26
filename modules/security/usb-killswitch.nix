{ config, lib, pkgs, ... }:
{
  services.udev.extraRules = ''
    ACTION=="remove", SUBSYSTEM=="block", ENV{ID_FS_LABEL}=="NIXHEADER", \
    RUN+="${pkgs.systemd}/bin/systemctl poweroff --force --force"
  '';
}