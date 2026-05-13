{ pkgs, inputs, ... }:
let
  prebuild = pkgs.buildGoModule {
    name = "apparmor-d-prebuild";
    src = inputs.apparmor-d;
    vendorHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # fill in after first build
    subPackages = [ "cmd/prebuild" ];
  };

  apparmor-d-nixos = pkgs.stdenv.mkDerivation {
    name = "apparmor-d-nixos";
    src = inputs.apparmor-d;
    nativeBuildInputs = [ prebuild ];
    buildPhase = ''
      cp ${./tunables/nixos} apparmor.d/tunables/multiarch.d/nixos
      DISTRIBUTION=arch prebuild --buildir .build
    '';
    installPhase = ''
      mkdir -p $out/etc/apparmor.d
      cp -r .build/apparmor.d/* $out/etc/apparmor.d/
    '';
  };
in {
  security.apparmor.packages = [ apparmor-d-nixos ];
}