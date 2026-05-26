{ pkgs, lib, }:
let
  tagHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  source = pkgs.fetchFromGitHub {
    hash = tagHash;
    owner = "";
    repo = "";
    tag = "";
  };
in 
flavor: accent: pkgs.stdenv.mkDerivation {
  name = "catppuccin-${lib.toLower flavor}.${lib.toLower accent}-zen-usercss";
  src = source;
  checkPhase = ''
    if [ ! -d themes/${flavor} ]; then
      echo "Flavor does not exist."
      exit 1
    fi
    if [ ! -d themes/${flavor}/${accent} ]; then
      echo "Accent does not exist."
      exit 1
    fi
  '';
  buildPhase = ''
    exit 0
  ''; # no build phase needed
  installPhase = ''
    cp themes/Frappe/Blue/zen-logo-frappe.svg $out
    cp themes/Latte/Blue/zen-logo-latte.svg $out
    cp themes/Macchiato/Blue/zen-logo-macchiato.svg $out
    cp themes/Mocha/Blue/zen-logo-mocha.svg $out
    cp themes/${flavor}/${accent}/userChrome.css $out
    cp themes/${flavor}/${accent}/userContent.css $out
  '';
}