{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "screenshot";
  runtimeInputs = with pkgs; [ grim slurp wl-clipboard ];
  text = ''
    #!/usr/bin/env bash
    set -euo pipefail
    grim -g "$(slurp)" - | wl-copy
  '';
}