{ pkgs, ... }:
let
  tagHash = "sha256-T4pST1enDAiI9Xhm9iBojPEC0mtOAoERlAHJpntxnHY=";
  source = pkgs.fetchFromGitHub {
    hash = tagHash;
    owner = "roddhjav";
    repo = "apparmor.d";
    tag = "v0.4907.0";
  };
  prebuild = pkgs.buildGoModule {
    name = "apparmor-d-prebuild";
    src = source;
    vendorHash = null;
    subPackages = [ "cmd/prebuild" ];
  };
  tunables-nixos = pkgs.writeTextFile {
    name = "tunables-nixos";
    text = ''
      # extends standard path variables to include nix store paths.
      # the wildcard covers all package hashes, which change on updates.
      # /run/current-system/sw/ covers system-level symlinks.
      
      @{bin} += /nix/store/*/bin
      @{bin} += /run/current-system/sw/bin
      
      @{sbin} += /nix/store/*/sbin
      @{sbin} += /run/current-system/sw/sbin
      
      @{lib} += /nix/store/*/lib{,exec,32,64}
      @{lib} += /nix/store/*/lib64
      @{lib} += /run/current-system/sw/lib{,exec,32,64}
    '';
  };
in
pkgs.stdenv.mkDerivation {
  name = "apparmor-d-nix-patch";
  src = source;
  nativeBuildInputs = [ prebuild ];
  buildPhase = ''
    cp ${tunables-nixos} apparmor.d/tunables/multiarch.d/nixos
    DISTRIBUTION=arch prebuild --buildir .build
  '';
  installPhase = ''
    mkdir -p $out/etc/apparmor.d
    cp -r .build/apparmor.d/* $out/etc/apparmor.d/
    find $out/etc/apparmor.d/disable -xtype l -delete
  '';
}