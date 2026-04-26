{ config, pkgs, ... }:
let
  lockoutScript = pkgs.writeShellScript "luks-lockout" ''
    #!/bin/sh
    COUNTER_FILE="/boot/luks-header/unlock-attempts"
    
    COUNT=0
    if [ -f "$COUNTER_FILE" ]; then
      COUNT=$(cat "$COUNTER_FILE")
    fi
    
    if [ "$COUNT" -ge 11 ]; then
      echo "Too many failed unlock attempts. System will no longer boot."
      echo "Mount USB on trusted machine and delete $COUNTER_FILE to unlock."
      sleep infinity
    fi
    
    if [ "$COUNT" -ge 3 ]; then
      DELAY=$((2 ** (COUNT - 3)))
      echo "Warning: $((11 - COUNT)) attempts remaining before lockout."
      echo "Next unlock attempt will be delayed for $DELAY seconds."
      sleep "$DELAY"
    fi
    
    echo "$((COUNT + 1))" > "$COUNTER_FILE"
    
  '';
in
{
  boot.initrd.systemd.services.luks-lockout-pre = {
    description = "LUKS unlock attempt lockout (pre)";
    wantedBy = [ "systemd-cryptsetup@nixos.service" ];
    before  = [ "systemd-cryptsetup@nixos.service" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${lockoutScript}";
    };
  };
  boot.initrd.systemd.services.luks-lockout-reset = {
    description = "LUKS unlock attempt counter reset";
    wantedBy = [ "systemd-cryptsetup@nixos.service" ];
    after = [ "systemd-cryptsetup@nixos.service" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/sh -c 'echo 0 > /boot/luks-header/unlock-attempts'";
    };
  };
  boot.initrd.systemd.storePaths = [ lockoutScript ];
}