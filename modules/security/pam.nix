{ config, lib, pkgs, ... }:
{
  security.pam.services.login.failDelay = {
    enable = true;
    delay = 4000000;
  };
  security.pam.services.sudo.failDelay = {
    enable = true;
    delay = 4000000;
  };
  security.pam.services.greetd.failDelay = {
    enable = true;
    delay = 4000000;
  };
  security.pam.loginLimits = [
    { domain = "@users"; item = "nproc";  type = "soft"; value = "1024"; }
    { domain = "@users"; item = "nproc";  type = "hard"; value = "8192"; }
  ];
}
