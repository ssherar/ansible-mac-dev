# Spec: Shell Configuration Drift Detection

## Domain
Default shell, Fish shell config, Starship prompt config

## Purpose
Detect whether the default shell is fish, and whether the managed config files (`config.fish`, `starship.toml`) match the versions tracked in the playbook. Resolve each deviation interactively.

## Prerequisites
- Fish shell installed (`which fish`)
- Working directory: repo root (`/Users/sbsherar/projects/ansible-mac-dev`)

## Sensitive Data Rules
- `config.fish` and `starship.toml` contain no credentials — their diffs may be shown
- Do not read or display any values from `config.yml`

---

## Step 1: Gather Desired State

From `tasks/shell.yml` and `files/shell/`, the desired state is:

- Default shell: fish (path returned by `which fish`, e.g. `/opt/homebrew/bin/fish`)
- `~/.config/fish/config.fish` matches `files/shell/config.fish` in the repo
- `~/.config/starship.toml` matches `files/shell/starship.toml` in the repo

---

## Step 2: Gather Current Machine State

```bash
REPO=/Users/sbsherar/projects/ansible-mac-dev

# Check default shell (value shown is not sensitive)
dscl . -read /Users/$(whoami) UserShell | awk '{print $2}'

# Check fish config exists
stat ~/.config/fish/config.fish 2>/dev/null && echo "EXISTS" || echo "MISSING"

# Check starship config exists
stat ~/.config/starship.toml 2>/dev/null && echo "EXISTS" || echo "MISSING"

# Diff config.fish (show diff — no sensitive data in this file)
diff ~/.config/fish/config.fish "$REPO/files/shell/config.fish" 2>/dev/null
echo "config.fish diff exit code: $?"

# Diff starship.toml (show diff — no sensitive data in this file)
diff ~/.config/starship.toml "$REPO/files/shell/starship.toml" 2>/dev/null
echo "starship.toml diff exit code: $?"
```

Exit code `0` from diff = files match. Exit code `1` = files differ.

---

## Step 3: Compute Drift

| Check | Expected | Drift if |
|-------|----------|----------|
| Default shell | fish path | shell is not fish |
| `~/.config/fish/config.fish` | matches repo source | file missing or diff ≠ 0 |
| `~/.config/starship.toml` | matches repo source | file missing or diff ≠ 0 |

---

## Step 4: Interactive Resolution

### Wrong or missing default shell
> "The current default shell is **`<current-shell>`**. The playbook sets it to fish."
>
> Options:
> - **Change to fish now** → run `chsh -s $(which fish)` (requires sudo/password prompt)
> - **Skip** → note in report

### config.fish differs or missing
> "**`~/.config/fish/config.fish`** differs from the playbook version (diff shown above)."
>
> Show the diff output, then ask:
>
> Options:
> - **Overwrite with playbook version** → copy `files/shell/config.fish` to `~/.config/fish/config.fish`
> - **Update playbook file to match local** → copy `~/.config/fish/config.fish` to `files/shell/config.fish`
> - **Skip** → leave as-is, note in report

### starship.toml differs or missing
> "**`~/.config/starship.toml`** differs from the playbook version (diff shown above)."
>
> Show the diff output, then ask:
>
> Options:
> - **Overwrite with playbook version** → copy `files/shell/starship.toml` to `~/.config/starship.toml`
> - **Update playbook file to match local** → copy `~/.config/starship.toml` to `files/shell/starship.toml`
> - **Skip** → leave as-is, note in report

Apply the chosen action **immediately** before moving to the next item.

---

## Step 5: Write Drift Report

Write `drift-report-shell.md` to the repo root with:

```markdown
# Drift Report: Shell Configuration
Date: <ISO date>

## Default Shell
- Current: <shell path>
- Expected: <fish path>
- Status: <ok | changed | skipped>

## config.fish
- Status: <match | diff-applied | playbook-updated | skipped>
- Diff summary: <number of lines changed, or "no diff">

## starship.toml
- Status: <match | diff-applied | playbook-updated | skipped>
- Diff summary: <number of lines changed, or "no diff">
```

---

## Files Modified
- `~/.config/fish/config.fish` — if "Overwrite with playbook version" chosen
- `~/.config/starship.toml` — if "Overwrite with playbook version" chosen
- `files/shell/config.fish` — if "Update playbook file to match local" chosen
- `files/shell/starship.toml` — if "Update playbook file to match local" chosen
- `drift-report-shell.md` — written at repo root

## Handoff Notes
- Depends on `spec-brew-packages.md` completing first (fish must be installed)
- Can run **in parallel** with `spec-vscode.md`, `spec-git.md`, `spec-dock.md`
