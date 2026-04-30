{ pkgs, ... }:
let
  fido2HybridUnlock = pkgs.writeShellScript "fido2-hybrid-unlock" ''
    #!/usr/bin/env bash
    # invoked as fido2-hybrid-unlock <luks_device> <credential_id_file> <lockout_file>
    # requires libfido2, argon2, systemd-ask-password
    # requires /boot/luks-header/ to be mounted.
    # unlocks a LUKS volume using both a FIDO2 device and a password

    set -euo pipefail

    LUKS_DEVICE="${1}"
    CREDENTIAL_ID_FILE="${2}"
    LOCKOUT_FILE="${3}"
    DEVICE=""

    find_fido2_device() {
      for i in $(seq 1 20); do
        DEVICE=$(fido2-token -L 2>/dev/null | head -1 | cut -d: -f1)
        [ -n "$DEVICE" ] && return 0
        sleep 0.5
      done
      echo "No FIDO2 device found" >&2
      exit 1
    }
    
    get_salt() {
      PERSONALIZATION_CONSTANT="pyria:modules/boot/luks/fido2.nix"
      
      echo "Touch your security key (1/2)" >&2
      printf '%s' "$PERSONALIZATION_CONSTANT" \
        | fido2-assert \
            -u \
            -h \
            -c "$(cat "$CREDENTIAL_ID_FILE")" \
            "$DEVICE" \
            | head -1
    }
    
    # invoked as attempt_unlock <attempt_number> <luks_device> <salt>
    attempt_unlock() {
      local passphrase
      passphrase=$(systemd-ask-password "Enter passphrase for ${2} (Attempt $1/10: ")
      
      echo "Deriving key, this may take a few moments..." >&2
      
      local kdf_output
      kdf_output=$(printf '%s' "$passphrase" \
        | argon2 "$3" \
            -id -t 3 -m 23 \
            -p 4 -l 32 -r) \
        || { unset passphrase; return 1; }
      unset passphrase
      echo "Touch your security key (2/2)" >&2
      
      local luks_key
      luks_key=$(printf '%s' "$kdf_output" \
        | fido2-assert \
            -u -h \
            -c "$(cat "$CREDENTIAL_ID_FILE")" \
            "$DEVICE" \
            | head -1) \
        || { unset kdf_output; return 1; }
      unset kdf_output
      
      printf '%s' "$luks_key" \
        | cryptsetup open "$2" nixos --header /boot/luks-header/nixos.img --key-file=- > /dev/null 2>&1
      return $?
    }
    # invoked as auth_loop <luks_device> <lockout_file>
    auth_loop() {
      local count=0
      if [ -f "$2" ]; then
        count=$(cat "$2")
        if ! echo "$count" | grep -q '^[0-9]*$'; then
          echo "LOCKOUT: Counter file is corrupted or tampered with. System will not boot." >&2
          echo "Mount USB on a trusted machine and delete $2 to unlock." >&2
          sleep infinity
        elif [ "$count" -ge 11 ]; then
          echo "LOCKOUT: Too many failed attempts. System will not boot." >&2
          echo "Mount USB on a trusted machine and delete $2 to unlock." >&2
          sleep infinity
        fi
      fi
      local salt
      salt=$(get_salt)
      while true; do
        if [ "$count" -ge 11 ]; then
          echo "LOCKOUT: Too many failed attempts. System will not boot." >&2
          echo "Mount USB on a trusted machine and delete $2 to unlock." >&2
          sleep infinity
        fi
        if [ "$count" -ge 3 ]; then
          local delay
          delay=$((2 ** (count - 3)))
          echo "Waiting $delay seconds before next attempt..." >&2
          sleep "$delay"
        fi
        echo "$((count + 1))" > "$2"
        if ! attempt_unlock "$((count+1))" "$1" "$salt"; then
          echo "Failed attempt $((count + 1))" >&2
          count=$((count + 1))
        else
          echo "Successfully unlocked" >&2
          echo 0 > "$2"
          return 0
        fi
      done      
    }
    find_fido2_device
    auth_loop "$LUKS_DEVICE" "$LOCKOUT_FILE"
  '';
in 
{
  boot.initrd.systemd.enable = true;
  boot.initrd.kernelModules = [ "vfat" "ext4" "btrfs"];
  
  # workaround for nixpkgs#368856
  boot.initrd.services.udev.packages = [
    (pkgs.runCommand "udev-fido2-rules" {} ''
      mkdir -p $out/lib/udev/rules.d
      cp ${pkgs.systemd}/lib/udev/rules.d/60-fido-id.rules \
        $out/lib/udev/rules.d/60-fido-id.rules
    '')
  ];
  
  boot.initrd.systemd.storePaths = [
    fido2HybridUnlock
    "${pkgs.libfido2}/bin/fido2-assert"
    "${pkgs.libfido2}/bin/fido2-token"
    "${pkgs.libargon2}/bin/argon2"
    "${pkgs.cryptsetup}/bin/cryptsetup"
    "${pkgs.systemd}/lib/udev/fido_id"
  ];
  
  # header drive
  boot.initrd.luks.devices."luks-header" = {
    device = "/dev/disk/by-partlabel/header";
    crypttabExtraOpts = [
      "fido2-device=auto"
      "token-timeout=0"
    ];
  };
  fileSystems."/boot/luks-header".neededForBoot = true;
  
  # main drive
  boot.initrd.systemd.services.fido2-hybrid-unlock = {
    description = "FIDO2 hybrid LUKS unlock";
    wantedBy = [ "cryptsetup.target" ];
    before = [ "cryptsetup.target" ];
    after = [
      "systemd-udev-settle.service"
      "dev-disk-by\\x2dpartlabel-nixos.device"
      "systemd-cryptsetup@luks-header.service"
      "boot-luks\\x2dheader.mount"
    ];
    requires = [
      "dev-disk-by\\x2dpartlabel-nixos.device"
      "systemd-cryptsetup@luks-header.service"
      "boot-luks\\x2dheader.mount"
    ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${fido2HybridUnlock} /dev/disk/by-partlabel/nixos /boot/luks-header/credential.id /boot/luks-header/unlock-attempts";
    };
  };
}