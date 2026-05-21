{ rustPlatform, lib }:

rustPlatform.buildRustPackage {
  pname = "pyria-sudo";
  version = "0.1.0";
  
  src = lib.cleanSource ../../crates/pyria;
  cargoLock.lockFile = ../../crates/pyria/Cargo.lock;
  
  cargoBuildFlags = [ "--bin" "pyria" "--features" "core" "bin" "interactive" "crypto" ];
  
  postInstall = ''
    find $out/bin -type f ! -name pyria-sudo -delete
  '';
  
  meta = {
    description = "multi-use specialized system manager for the 'pyria' nixOS flake";
    mainProgram = "pyria";  
    license = lib.licenses.agpl3Only;  
  };
}