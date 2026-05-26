{ inputs, config, pkgs, lib, nixgl, ... }:
let
  gl = pkg: let
    bin = pkg.meta.mainProgram or pkg.pname;
    wrapper = pkgs.writeShellScriptBin bin ''
      exec ${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel ${pkg}/bin/${bin} "$@"
    '';
  in pkgs.symlinkJoin {
    name = bin;
    paths = [ wrapper pkg ];
  };
in {
  home.username = "aenri";
  home.homeDirectory = "/home/aenri";
  home.stateVersion = "25.11";
  home.sessionVariables = {
    EDITOR = "nvim";
  };
  imports = [
    ../../nix/home-modules/pyria-sudo.nix
    ./home/scripts/default.nix
    ./home/zsh.nix
    ./home/dev.nix
    ./home/zed.nix
    ./home/niri.nix
    ./home/zen.nix
    ./home/steam.nix 
  ];
  home.packages = with pkgs; [
    zed-editor
    (gl signal-desktop)
    legcord
    paru
    graphene-hardened-malloc
    (gl vesktop)
    (gl obsidian)
    tailscale
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
