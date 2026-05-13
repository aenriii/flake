{ ... }:
{
  imports = [
    ./config/common.nix  # common kernel configuration, always imported and always added
    ./config/fortress.nix # fortress kernel configuration - sacrificing performance for security
    ./flavors/common.nix # default kernel flavor - most up-to-date mainline kernel.
    ./flavors/hardened.nix # hardened kernel flavor - locally compiled linux-hardened kernel.
    ./flavors/lts.nix # lts kernel flavor - most up-to-date lts kernel.
  ];
}