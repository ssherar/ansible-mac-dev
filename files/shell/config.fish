if status is-interactive
  set -U fish_greeting "🐠"
  set -u fish_user_paths /Users/sbsherar/.local/bin $fish_user_paths

  set -Ux PYENV_ROOT $HOME/.pyenv
  set -U fish_user_paths $PYENV_ROOT/bin

  /opt/homebrew/bin/brew shellenv | source
  starship init fish | source
  pyenv init - fish | source
  direnv hook fish | source
end
