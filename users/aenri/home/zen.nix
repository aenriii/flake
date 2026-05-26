{ inputs, pkgs, lib, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  zen-browser = inputs.zen-browser.packages.${system}.zen-browser-unwrapped;
  prefs = import ./firefox/prefs.nix;  
in
{
  home.packages = [
    (pkgs.wrapFirefox zen-browser {
      extraPrefs = lib.concatLines (
          lib.mapAttrsToList (
            name: value: ''lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});''
          ) prefs
        );
    
      extraPolicies = 
        { ExtensionSettings = import ./firefox/extensions.nix; }
        // import ./firefox/policies.nix;
    })
  ];
}