# Spec: Homebrew Cask Drift Detection

## Domain
Homebrew cask applications

## Purpose
Detect which cask apps are installed on the local machine but not tracked in `default.config.yml`, and which are defined in the config but missing from the machine. Resolve each deviation interactively.

## Prerequisites
- Homebrew installed (`which brew`)
- Working directory: repo root (`/Users/sbsherar/projects/ansible-mac-dev`)

## Sensitive Data Rules
- No credential values, SSH keys, or `config.yml` values may appear in output or reports
- Cask names are not sensitive — they can be listed freely

---

## Step 1: Gather Desired State

Read `default.config.yml` and extract the cask list. The desired casks are:

```
1password
1password-cli
arc
chatgpt
docker
font-mononoki-nerd-font
iterm2
notion
multipass
postman
slack
visual-studio-code
hashicorp-vagrant
```

---

## Step 2: Gather Current Machine State

```bash
# List all installed casks
brew list --cask | sort
```

Additionally, check for App Store equivalents for apps that may be installed outside Homebrew:

```bash
# Check if apps exist in /Applications regardless of install source
ls /Applications/ | sort
ls ~/Applications/ | sort
```

Common casks with App Store equivalents: `arc`, `chatgpt`, `slack`, `notion`, `1password`.

---

## Step 3: Compute Drift

- **MISSING**: in `default.config.yml` but not in `brew list --cask` output
- **EXTRA**: in `brew list --cask` output but not in `default.config.yml`
- **ALT SOURCE**: in `default.config.yml`, not in `brew list --cask`, but `/Applications/<AppName>.app` exists (likely App Store install)

For **ALT SOURCE** items: these are not truly missing — ask the user if they want to track them via Homebrew or leave them as App Store installs.

---

## Step 4: Interactive Resolution

For **each** deviation found, pause and ask the user:

### Extra cask (installed via brew, not in config)
> "**`<cask>`** is installed via Homebrew but not tracked in `default.config.yml`."
>
> Options:
> - **Add to config** → append to `homebrew_cask_apps` in `default.config.yml`
> - **Uninstall** → run `brew uninstall --cask <cask>`
> - **Skip** → leave as-is, note in report

### Missing cask (in config, not installed by brew)
> "**`<cask>`** is defined in config but not installed."
>
> Options:
> - **Install now** → run `brew install --cask <cask>`
> - **Remove from config** → remove entry from `homebrew_cask_apps` in `default.config.yml`
> - **Skip** → leave as-is, note in report

### Alt source cask (in config, app exists but not via brew)
> "**`<AppName>.app`** exists in /Applications but was not installed via Homebrew. It is listed in `default.config.yml`."
>
> Options:
> - **Keep as App Store install, remove from config** → remove from `homebrew_cask_apps`
> - **Re-install via Homebrew** → run `brew install --cask <cask>` (may conflict)
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

Cask tasks should show `ok` or `skipping` — not `changed`.

---

## Step 6: Write Drift Report

Write `drift-report-brew-casks.md` to the repo root with:

```markdown
# Drift Report: Homebrew Casks
Date: <ISO date>

## Resolved
- <cask>: <action taken>
...

## Skipped
- <cask>: extra/missing/alt-source (skipped by user)
...

## No Change Needed
- Count: <n> casks already matched desired state
```

**Do not include** any credential values or config.yml contents in this report.

---

## Files Modified
- `default.config.yml` — if any "Add to config" or "Remove from config" actions were taken
- `drift-report-brew-casks.md` — written at repo root

## Handoff Notes
- Can run **in parallel** with `spec-brew-packages.md`, `spec-git.md`, `spec-dock.md`
- `spec-vscode.md` depends on `visual-studio-code` being installed — run this spec first
