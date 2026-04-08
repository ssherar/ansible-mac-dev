# Drift Report: Homebrew Formulae
Date: 2026-04-08

## Summary
- No MISSING formulae (all desired packages were already installed)
- 34 EXTRA formulae found (installed but not previously tracked)
- 20 added to config, 13 skipped

## Added to config (homebrew_installed_packages)
- act
- ansible-lint
- argocd
- aws-sso-cli
- copa
- ffmpeg
- graphviz
- helm
- htop
- jupyterlab
- k9s
- kubernetes-cli
- mkcert
- ollama
- prowler
- qemu
- renovate
- rtk
- the_silver_searcher
- trivy

## Skipped (installed but not tracked — user chose to leave as-is)
- ansible (managed outside playbook)
- azure-cli
- cocoapods
- docker (provided by Docker Desktop cask)
- docker-buildx (provided by Docker Desktop cask)
- dockutil (installed by geerlingguy.mac.dock role as dependency)
- lacework-cli (via lacework/tap)
- libpq
- snyk-cli
- sox
- spacectl (via spacelift-io/spacelift tap)
- telnet
- tfsec

## No Change Needed
- 17 formulae already matched desired state (awscli, fish, jq, fswatch, git, gh, go, gpg, httpie, nmap, openssl, opa, podman, podman-compose, pyenv, starship, watch)
- Tapped formulae present: terraform, packer, goreleaser
