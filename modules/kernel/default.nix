{ ... }:
{
  imports = [
    ./config/common.nix  # common kernel configuration, always imported and always added
    ./config/fortress.nix # fortress kernel configuration - sacrificing performance for security
    ./config/hardened.nix # hardened kernel configuration - daily-drivable
    ./config/loose.nix # loose kernel configuration - compatability for gaming 
    ./flavors/common.nix # default kernel configuration - most up-to-date mainline kernel.
    ./flavors/hardened.nix # hardened kernel configuration - locally compiled linux-hardened kernel.
  ];
}