{ pkgs, ... }:
  let gamescope-wrapped = pkgs.writeShellScriptBin "gamescope" ''
    LD_PRELOAD=${pkgs.graphene-hardened-malloc}/lib/libhardened_malloc-light.so \
    exec ${pkgs.nixgl.nixVulkanIntel}/bin/nixVulkanIntel ${pkgs.gamescope}/bin/gamescope "$@"
  '';
  steam = pkgs.steam.override {
    extraPkgs = pkgs': with pkgs'; [
      libXcursor
      libXi
      libXinerama
      libXScrnSaver
      libpng
      libpulseaudio
      libvorbis
      stdenv.cc.cc.lib
      libkrb5
      keyutils
      gamescope-wrapped
    ];
  };
  steam-wrapped = pkgs.writeShellScriptBin "steam" ''
    QT_QPA_PLATFORM=xcb exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${steam}/bin/steam "$@"
  '';
in
{
  home.packages = [
    steam-wrapped
  ];
}
