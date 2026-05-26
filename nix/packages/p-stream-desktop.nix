{ pkgs, lib, ... }:
let
  pstream-version = "1.2.6";
  revHash = "sha256-igH5Ii6Z1H34ufh8gCn2oZjN6Er8xdBLsNwl4t/jxjA=";
  desktop = pkgs.writeTextFile {
    name = "p-stream-desktop.desktop";
    text = ''
      [Desktop Entry]
      Categories=Multimedia
      Exec=p-stream-desktop %U
      GenericName=P-Stream
      Keywords=pstream;p-stream
      Name=P-Stream Desktop
      Type=Application
      Version=${pstream-version}
    '';
  };
  repo = pkgs.fetchFromGitHub {
    hash = revHash;
    owner = "xp-technologies-dev";
    repo = "p-stream-desktop";
    rev = "4436e55b1a0deddb8ab93fc74e61dcd77ad5059f";
  };
  electron-headers = pkgs.fetchurl {
      url = "https://www.electronjs.org/headers/v${pkgs.electron.version}/node-v${pkgs.electron.version}-headers.tar.gz";
      hash = "sha256-Vi6m/9rgYJQdRmDiEB5eCGw7rNJqDCEesYs9KAsPYqc=";
  };
  package = pkgs.stdenv.mkDerivation {
    pname = "p-stream-desktop";
    version = pstream-version;
    src = repo;
  
    pnpmDeps = pkgs.fetchPnpmDeps {
      pname = "p-stream-desktop";
      version = pstream-version;
      src = repo;
      fetcherVersion = 3;
      hash = "sha256-INPX3dBrs+gRdv+9/6qq+EWDJLTlTUpUZZoX+yRtlog=";
    };
  
    nativeBuildInputs = with pkgs; [
      electron
      nodejs
      pnpm
      pnpmConfigHook
      python314
    ];
  
    buildPhase = ''
      runHook preBuild
      export HOME=$(mktemp -d)

      # set up electron-gyp headers cache so node-gyp doesn't fetch
      mkdir -p $HOME/.electron-gyp/${pkgs.electron.version}
      tar -xf ${electron-headers} \
        -C $HOME/.electron-gyp/${pkgs.electron.version} \
        --strip-components=1
      echo 9 > $HOME/.electron-gyp/${pkgs.electron.version}/installVersion
      export npm_config_devdir=$HOME/.electron-gyp
      export npm_config_nodedir=$HOME/.electron-gyp/${pkgs.electron.version}
      
      pnpm exec electron-builder --linux --dir \
        -c.electronDist=${pkgs.electron}/libexec/electron \
        -c.electronVersion=${pkgs.electron.version}
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/applications $out/opt/PStream/resources
      cp ${desktop} $out/share/applications/p-stream-desktop.desktop
      cp dist/linux-unpacked/resources/app.asar $out/opt/PStream/resources
      runHook postInstall
    '';
  };
  runner = pkgs.writeShellApplication {
    name = "p-stream-desktop";
    runtimeInputs = with pkgs; [ package electron ];
    text = ''
      if [[ ''${NIXOS_SPEECH:-default} != "False" ]]; then NIXOS_SPEECH=True; else unset NIXOS_SPEECH; fi
      exec "${pkgs.electron}/bin/electron" \
        ${package}/opt/PStream/resources/app.asar \
        ''${NIXOS_SPEECH:+--enable-speech-dispatcher} \
        ''${NIXOS_OZONE_WL:+''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}} \
        "$@"
    '';
  };
in pkgs.symlinkJoin {
  name = "p-stream-desktop";
  paths = [ runner package ];
}