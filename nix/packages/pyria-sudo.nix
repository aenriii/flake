{ rustPlatform, lib }:

rustPlatform.buildRustPackage {
  pname = "pyria-sudo";
  version = "0.1.0";
  
  src = lib.cleanSource ../../crates/pyria;
  cargoLock.lockFile = ../../crates/pyria/Cargo.lock;
  
  cargoBuildFlags = [ "--bin" "pyria-sudo" ];
  
  postInstall = ''
    find $out/bin -type f ! -name pyria-sudo -delete
  '';
  
  meta = {
    description = "sudo-compatible argument shim for systemd-run0";
    mainProgram = "pyria-sudo";  
    license = lib.licenses.agpl3Only;  
  };
}