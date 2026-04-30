{ config, lib, pkgs, ... }:
{
  nix.settings = {
    require-sigs = true;
    sandbox = true;
    trusted-users = config.users.groups.wheel.members;
    allowed-users = [ "root" ] ++ config.users.groups.wheel.members;
  };
}