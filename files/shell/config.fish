if status is-interactive
  set -U fish_greeting "🐠"
  set -u fish_user_paths /Users/sbsherar/.local/bin $fish_user_paths

  /opt/homebrew/bin/brew shellenv | source
  starship init fish | source
end
