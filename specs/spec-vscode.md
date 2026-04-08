# Spec: VSCode Extension & Settings Drift Detection

## Domain
Visual Studio Code extensions and settings

## Purpose
Detect which VSCode extensions are installed but not tracked, which are tracked but missing, and whether the settings.json has drifted from what the playbook manages. Resolve each deviation interactively.

## Prerequisites
- VSCode installed at `/Applications/Visual Studio Code.app`
- VSCode CLI symlinked: `code --version` must work, or use full path
- Working directory: repo root (`/Users/sbsherar/projects/ansible-mac-dev`)

## Sensitive Data Rules
- Do **not** output `settings.json` values — only report key names (presence)
- No credential values or `config.yml` contents in any output

---

## Step 1: Gather Desired State

From `default.config.yml`:

**Desired extensions**:
```
1password.op-vscode
ms-python.python
ms-azuretools.vscode-docker
golang.go
github.copilot
```

**Desired settings keys** (from `files/vs_code_settings.json`):
Read the file and note which top-level keys it sets. This is the playbook's managed settings scope.

---

## Step 2: Gather Current Machine State

```bash
VSCODE_CLI="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

# List installed extensions
"$VSCODE_CLI" --list-extensions 2>/dev/null | sort

# Check settings.json exists
SETTINGS=~/Library/Application\ Support/Code/User/settings.json
stat "$SETTINGS" 2>/dev/null && echo "EXISTS" || echo "MISSING"

# List top-level keys only (not values) — safe to display
jq 'keys' "$SETTINGS" 2>/dev/null
```

---

## Step 3: Compute Extension Drift

- **MISSING**: in `visual_studio_code_extensions` but not in `--list-extensions` output
- **EXTRA**: in `--list-extensions` output but not in `visual_studio_code_extensions`
- **PRESENT**: in both

---

## Step 4: Compute Settings Drift

Read `files/vs_code_settings.json` from the repo. Compare its top-level keys against the keys present in `~/Library/Application Support/Code/User/settings.json`.

- If `settings.json` does not exist: report as MISSING
- If a key managed by the playbook is absent from `settings.json`: report as MISSING KEY
- If `settings.json` contains keys not in `files/vs_code_settings.json`: these are user-added and should **not** be flagged as drift (the playbook merges, not overwrites)

**Do not compare values** — only key presence for playbook-managed keys.

---

## Step 5: Interactive Resolution

For **each** extension deviation, pause and ask the user:

### Extra extension (installed, not in config)
> "**`<extension-id>`** is installed but not tracked in `default.config.yml`."
>
> Options:
> - **Add to config** → append to `visual_studio_code_extensions` in `default.config.yml`
> - **Uninstall** → run `"$VSCODE_CLI" --uninstall-extension <extension-id>`
> - **Skip** → leave as-is, note in report

### Missing extension (in config, not installed)
> "**`<extension-id>`** is defined in config but not installed."
>
> Options:
> - **Install now** → run `"$VSCODE_CLI" --install-extension <extension-id>`
> - **Remove from config** → remove from `visual_studio_code_extensions` in `default.config.yml`
> - **Skip** → leave as-is, note in report

For **settings drift**, pause and ask:

### Settings missing or drifted
> "The settings managed by the playbook (`files/vs_code_settings.json`) may not be applied."
>
> Options:
> - **Re-apply playbook settings** → merge `files/vs_code_settings.json` into `settings.json` (keys listed, not values)
> - **Update playbook file** → copy current `settings.json` managed keys into `files/vs_code_settings.json`
> - **Skip** → leave as-is, note in report

Apply the chosen action **immediately** before moving to the next item.

---

## Step 6: Write Drift Report

Write `drift-report-vscode.md` to the repo root with:

```markdown
# Drift Report: VSCode
Date: <ISO date>

## Extensions Resolved
- <extension-id>: <action taken>
...

## Extensions Skipped
- <extension-id>: extra/missing (skipped by user)
...

## Settings
- Status: <ok | applied | skipped>
- Keys checked: <list of key names only — no values>

## No Change Needed
- Count: <n> extensions already matched desired state
```

**Do not include** settings values, credential values, or config.yml contents in this report.

---

## Files Modified
- `default.config.yml` — if extensions were added/removed from config
- `files/vs_code_settings.json` — if "Update playbook file" was chosen
- `~/Library/Application Support/Code/User/settings.json` — if "Re-apply" was chosen
- `drift-report-vscode.md` — written at repo root

## Handoff Notes
- Depends on `spec-brew-casks.md` completing first (VSCode must be installed)
- Can run **in parallel** with `spec-git.md`, `spec-shell.md`, `spec-dock.md`
