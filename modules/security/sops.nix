{ config, lib, pkgs, ... }:
{
  sops = {
    defaultSopsFile = ../../secrets/deaddove/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  };
}