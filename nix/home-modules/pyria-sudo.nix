{ config, lib, pkgs, ... }:

let
  cfg = config.programs.pyria-sudo;
  sudoShim = pkgs.writeShellApplication {
      name = "sudo";
      text = ''
        exec -a sudo ${lib.getExe cfg.package} "$@"
      '';
    };
in
{
  options.programs.pyria-sudo = {
    enable = lib.mkEnableOption "pyria-sudo (run0 wrapper)";
    
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pyria-sudo;
      defaultText = lib.literalExpression "pkgs.pyria-sudo";
      description = "The pyria-sudo package to install.";
    };
    
    aliasSudo = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        If true, alias `sudo` to `pyria-sudo` in the user's interactive shells.
      '';
    };

    shadowSudo = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        If true, overshadow `sudo`. In order to achieve this, it also edits
        your PATH in order to set your `~/.local/bin` as the first searched
        path.
      '';
    };
  };
  
  config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        home.packages = [ cfg.package ];
      }
      
      (lib.mkIf cfg.aliasSudo {
        home.shellAliases.sudo = "${lib.getExe cfg.package}";
      })
      
      (lib.mkIf cfg.shadowSudo {
        # shadow /usr/bin/sudo in PATH by putting a pyria-sudo link in ~/.local/bin
        # and setting that to the first-searched path
        home.file.".local/bin/sudo" = {
          source = "${sudoShim}/bin/sudo";
        };
        home.sessionPath = lib.mkBefore [ "$HOME/.local/bin" ];
        systemd.user.sessionVariables = {
          PATH = "%h/.local/bin:$PATH";
        };
        xdg.configFile."environment.d/10-pyria-sudo.conf".text = ''
          PATH=''${HOME}/.local/bin:''${PATH}
        '';
        
        # failsafe: show up in other shells, just incase they didnt get the
        # message in some other way.
        programs.bash.initExtra = lib.mkIf config.programs.bash.enable ''
          sudo() {
            command ${lib.getExe cfg.package} "$@"
          }
          export -f sudo
        '';
        
        programs.zsh.initContent = lib.mkIf config.programs.zsh.enable ''
          sudo() {
            command ${lib.getExe cfg.package} "$@"
          }
        '';
        
        programs.fish.shellInit = lib.mkIf config.programs.fish.enable ''
          function sudo --wraps=sudo
            command ${lib.getExe cfg.package} $argv
          end
        '';
      })
    ]);
}