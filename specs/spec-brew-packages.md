# Spec: Homebrew Formula Drift Detection

## Domain
Homebrew formulae (non-cask packages)

## Purpose
Detect which brew formulae are installed on the local machine but not tracked in `default.config.yml`, and which are defined in the config but missing from the machine. Resolve each deviation interactively.

## Prerequisites
- Homebrew installed (`which brew`)
- Ansible installed and collections present (`ansible-galaxy collection list | grep geerlingguy`)
- Working directory: repo root (`/Users/sbsherar/projects/ansible-mac-dev`)

## Sensitive Data Rules
- No credential values, SSH keys, or `config.yml` values may appear in output or reports
- Formula names are not sensitive — they can be listed freely

---

## Step 1: Gather Desired State

Read `default.config.yml` and extract the formula list. The desired formulae are:

**Plain formulae** (from `homebrew_installed_packages`, excluding tap-prefixed entries):
```
awscli, fish, jq, fswatch, git, gh, go, gpg, httpie, nmap, openssl, opa,
podman, podman-compose, pyenv, starship, watch
```

**Tapped formulae** (from `homebrew_installed_packages`, tap-prefixed entries):
```
hashicorp/tap/terraform, hashicorp/tap/packer, goreleaser/tap/goreleaser
```

---

## Step 2: Gather Current Machine State

```bash
# List all installed formulae
brew list --formula | sort

# List installed tapped formulae (to cross-check tap-prefixed entries)
brew list --formula | sort
# Tapped formulae appear as their short names (terraform, packer, goreleaser)
# Verify tap source with: brew info <formula> | head -1
```

---

## Step 3: Compute Drift

Compare the two lists:

- **MISSING**: in `default.config.yml` but not in `brew list` output
- **EXTRA**: in `brew list` output but not in `default.config.yml`
- **PRESENT**: in both (no action needed)

Ignore formulae that are dependencies of other installed packages (i.e. not explicitly requested). Use `brew leaves` to identify top-level installs:

```bash
brew leaves | sort
```

Focus deviation detection on `brew leaves` output, not the full `brew list`.

---

## Step 4: Interactive Resolution

For **each** deviation found, pause and ask the user:

### Extra formula (installed, not in config)
> "**`<formula>`** is installed but not tracked in `default.config.yml`."
>
> Options:
> - **Add to config** → append to `homebrew_installed_packages` in `default.config.yml`
> - **Uninstall** → run `brew uninstall <formula>`
> - **Skip** → leave as-is, note in report

### Missing formula (in config, not installed)
> "**`<formula>`** is defined in config but not installed."
>
> Options:
> - **Install now** → run `brew install <formula>`
> - **Remove from config** → remove entry from `homebrew_installed_packages` in `default.config.yml`
> - **Skip** → leave as-is, note in report

Apply the chosen action **immediately** before moving to the next item.

---

## Step 5: Ansible Check (optional validation)

After resolving deviations, run ansible in check mode to confirm no remaining drift:

```bash
cd /Users/sbsherar/projects/ansible-mac-dev
ansible-playbook main.yml -i inventory --check --tags homebrew 2>&1 \
  | grep -E "TASK|changed|ok|failed|skipping"
```

All tasks should show `ok` or `skipping` — not `changed`.

---

## Step 6: Write Drift Report

Write `drift-report-brew-packages.md` to the repo root with:

```markdown
# Drift Report: Homebrew Formulae
Date: <ISO date>

## Resolved
- <formula>: <action taken>
...

## Skipped
- <formula>: extra/missing (skipped by user)
...

## No Change Needed
- Count: <n> formulae already matched desired state
```

**Do not include** any credential values or config.yml contents in this report.

---

## Files Modified
- `default.config.yml` — if any "Add to config" or "Remove from config" actions were taken
- `drift-report-brew-packages.md` — written at repo root

## Handoff Notes
- Run this spec **before** `spec-vscode.md` and `spec-shell.md` (those depend on brew installs)
- Can run **in parallel** with `spec-brew-casks.md`, `spec-git.md`, `spec-dock.md`
