function __prompt () {
  if [[ $? == 0 ]]; then
    local prompt_DOT="%F{75}●%f"
  else
    local prompt_DOT="%F{124}●%f"
  fi

  if [[ $UID == 0 || $EUID == 0 ]]; then
    local prompt_USER="%f%F{125}%n%f"
  else
    local prompt_USER="%f%F{75}%n%f"
  fi

  if [[ -v IN_NIX_SHELL ]]; then
    local prompt_HOST="%F{118}%m%f"
  else
    local prompt_HOST="%F{176}%m%f"
  fi

  local prompt_DIR="%F{177}%~%f"

  echo -e "$prompt_DOT $prompt_USER%F{white}@%f$prompt_HOST: $prompt_DIR $ "
}
export PS1='$(__prompt)'
