{ config, lib, ... }:
{
  options.pyria.specializations.fortress.enable = lib.mkEnableOption "fortress specialization";

  config = lib.mkIf config.pyria.specializations.fortress.enable {
    specialisation.fortress.configuration = {
      config.hostprofile.kernel.flavor = lib.mkForce "hardened";
      config.hostprofile.kernel.config = lib.mkForce "fortress";
    };
  };
}
