# Drift Report: Homebrew Casks
Date: 2026-04-08

## Resolved
- docker: removed from `homebrew_cask_apps` in default.config.yml (not installed, not needed)
- codeql: uninstalled via `brew uninstall --cask codeql` (extra, not tracked in config)
- goreleaser: added to `homebrew_cask_apps` in default.config.yml (was installed but untracked)

## Skipped
- codex: extra (installed via Homebrew, not in config — skipped by user)
- dbeaver-community: extra (installed via Homebrew, not in config — skipped by user)

## No Change Needed
- Count: 12 casks already matched desired state (1password, 1password-cli, arc, chatgpt, font-mononoki-nerd-font, hashicorp-vagrant, iterm2, multipass, notion, postman, slack, visual-studio-code)
