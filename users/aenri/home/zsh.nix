{ pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    initContent = ''
      for file in ~/.profile ~/.aliases ~/.path; do
        if [[ -f $file ]]; then source $file; fi
        if [[ -f $file.platform ]]; then source $file.platform; fi
        if [[ -f $file.${builtins.getEnv "HOST"} ]]; then source $file.${builtins.getEnv "HOST"}; fi
      done
      ${lib.readFile ./zsh/functions.zsh}
      ${lib.readFile ./zsh/prompt.zsh}
    '';
    setOptions = [ "PROMPT_SUBST" ];
    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.7.1";
          sha256 = "sha256-vpTyYq9ZgfgdDsWzjxVAE7FZH4MALMNZIFyEOBLm5Qo=";
        };
      }
      {
        name = "zsh-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-syntax-highlighting";
          rev = "0.7.1";
          sha256 = "sha256-gOG0NLlaJfotJfs+SUhGgLTNOnGLjoqnUp54V9aFJg8=";
        };
      }
    ];
    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
      ];
    };
    shellAliases = {
      testflake = "echo hello from your flake!";
    };
  };
}