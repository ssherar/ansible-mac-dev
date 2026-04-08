# Spec: Git Configuration Drift Detection

## Domain
Git global config structure and SSH config

## Purpose
Detect whether the git configuration structure (aliases, includeIf blocks, SSH host entries, subdirectory config files) matches what the playbook defines. Resolve each deviation interactively.

## Prerequisites
- Git installed (`git --version`)
- Working directory: repo root (`/Users/sbsherar/projects/ansible-mac-dev`)

## Sensitive Data Rules
- **NEVER** output `user.email`, `user.name`, or any credential values
- **NEVER** output SSH private key contents or paths to key files
- **NEVER** read or display any values from `config.yml`
- Check only for the **presence** of config keys and SSH host entries — not their values

---

## Step 1: Gather Desired State (Structure Only)

From `default.config.yml` and `tasks/git.yml`, the desired structure is:

**Git global aliases** (keys only):
- `alias.ci` must exist
- `alias.st` must exist

**Git includeIf blocks**:
- At least 1 `includeIf` entry in `~/.gitconfig` (for subdirectory-scoped configs)

**SSH config host entries**:
- `github.com` host block must exist in `~/.ssh/config`
- `gitlab.com` host block must exist in `~/.ssh/config`

**Subdirectory git config files**:
- At least one `.gitconfig` stub exists under `~/projects/personal/` (path from `git_sub_configs` in config)

---

## Step 2: Gather Current Machine State (Structure Checks Only)

```bash
# Check which aliases exist (keys only — do not show values)
git config --global --list 2>/dev/null | grep -E "^alias\." | cut -d= -f1

# Count includeIf blocks
git config --global --list 2>/dev/null | grep -c "includeif" || echo "0"

# Check SSH config host entries (host names only — do not show key paths or options)
grep -E "^Host " ~/.ssh/config 2>/dev/null

# Check subdirectory gitconfig stubs exist (file paths only — do not show contents)
find ~/projects/personal -name ".gitconfig" -maxdepth 2 2>/dev/null
```

---

## Step 3: Compute Drift

Evaluate each check:

| Check | Desired | How to detect |
|-------|---------|---------------|
| `alias.ci` | present | `git config --global alias.ci` returns 0 |
| `alias.st` | present | `git config --global alias.st` returns 0 |
| `includeIf` block | ≥1 | count from `--list \| grep includeif` |
| SSH `github.com` host | present | `grep "^Host github.com" ~/.ssh/config` |
| SSH `gitlab.com` host | present | `grep "^Host gitlab.com" ~/.ssh/config` |
| Subdirectory `.gitconfig` | ≥1 file | `find ~/projects/personal -name ".gitconfig"` |

---

## Step 4: Interactive Resolution

For **each** missing structural item, pause and ask the user:

### Missing git alias
> "Git alias **`<alias.key>`** is not set in `~/.gitconfig`."
>
> Options:
> - **Re-apply git tasks** → run `ansible-playbook main.yml -i inventory` (configure_git tasks)
> - **Skip** → note in report

### Missing includeIf block
> "No `includeIf` blocks found in `~/.gitconfig`. The playbook sets up per-directory git configs."
>
> Options:
> - **Re-apply git tasks** → run ansible git tasks
> - **Skip** → note in report

### Missing SSH host entry
> "SSH config is missing a Host entry for **`<host>`**."
>
> Options:
> - **Re-apply git tasks** → run ansible git tasks (will add the SSH config block)
> - **Skip** → note in report

### Missing subdirectory gitconfig file
> "No `.gitconfig` stub found under `~/projects/personal/`. The playbook creates these for per-directory identity."
>
> Options:
> - **Re-apply git tasks** → run ansible git tasks
> - **Remove from `git_sub_configs`** → remove the entry from `default.config.yml`
> - **Skip** → note in report

Apply the chosen action **immediately** before moving to the next item.

**Important**: When running ansible git tasks, confirm with the user before executing — this will write to `~/.gitconfig` and `~/.ssh/config`.

---

## Step 5: Write Drift Report

Write `drift-report-git.md` to the repo root with:

```markdown
# Drift Report: Git Configuration
Date: <ISO date>

## Structure Checks
- alias.ci: <present | missing | fixed | skipped>
- alias.st: <present | missing | fixed | skipped>
- includeIf blocks: <count found> (desired: ≥1) — <ok | fixed | skipped>
- SSH github.com host: <present | missing | fixed | skipped>
- SSH gitlab.com host: <present | missing | fixed | skipped>
- Subdirectory gitconfigs: <count found> — <ok | fixed | skipped>

## Actions Taken
- <description of what was changed>
```

**Do not include**: usernames, email addresses, SSH key contents, or any config.yml values.

---

## Files Modified
- `~/.gitconfig` — if ansible git tasks were re-applied
- `~/.ssh/config` — if ansible git tasks were re-applied
- `default.config.yml` — if entries were removed from `git_sub_configs`
- `drift-report-git.md` — written at repo root

## Handoff Notes
- This spec is **fully independent** — can run in parallel with all other specs
- Never expose values, only structure. If in doubt about whether something is sensitive, skip it.
