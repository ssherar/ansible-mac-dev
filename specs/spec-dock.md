# Spec: macOS Dock Configuration Drift Detection

## Domain
macOS Dock persistent apps

## Purpose
Detect which apps are in the Dock but not tracked in `default.config.yml` (`dockitems_persist`), and which are tracked but missing from the Dock. Resolve each deviation interactively.

## Prerequisites
- macOS with Dock running
- Working directory: repo root (`/Users/sbsherar/projects/ansible-mac-dev`)

## Sensitive Data Rules
- App names in the Dock are not sensitive — they can be listed freely
- Do not read or display any values from `config.yml`

---

## Step 1: Gather Desired State

From `default.config.yml`:

**Apps that should persist in the Dock** (in order):
```
Arc
Visual Studio Code
iTerm2
Slack
1Password
Mail
Calendar
Notion
```

**Apps that should be removed from the Dock**:
```
Safari, Launchpad, Maps, Photos, FaceTime, Messages, Contacts,
Reminders, Notes, Freeform, App Store, Podcasts, TV, Music,
System Settings, iPhone Mirroring
```

---

## Step 2: Gather Current Machine State

```bash
# List current persistent dock app labels (app names only — not plist paths)
defaults read com.apple.dock persistent-apps 2>/dev/null \
  | grep "file-label" \
  | sed 's/.*= "\(.*\)";/\1/'
```

This outputs one app name per line in current Dock order.

---

## Step 3: Compute Drift

- **EXTRA in dock**: app is in the Dock output but not in `dockitems_persist`
  - Sub-case: app is in `dockitems_remove` list but still present in Dock
- **MISSING from dock**: app is in `dockitems_persist` but absent from Dock output

Note: Order drift (app present but in wrong position) is not flagged — the playbook manages order, but positional drift is low priority. Flag only presence/absence.

---

## Step 4: Interactive Resolution

For **each** deviation found, pause and ask the user:

### Extra app in Dock (present, not in `dockitems_persist`)
> "**`<AppName>`** is in your Dock but not tracked in `default.config.yml`."
>
> Options:
> - **Add to `dockitems_persist`** → append entry to `dockitems_persist` list in `default.config.yml`
> - **Add to `dockitems_remove`** → append to `dockitems_remove` so it gets removed on next run
> - **Skip** → leave as-is, note in report

### App still in Dock despite being in `dockitems_remove`
> "**`<AppName>`** is in your Dock but is listed in `dockitems_remove` — the playbook should have removed it."
>
> Options:
> - **Re-apply dock role** → run `ansible-playbook main.yml -i inventory --tags dock`
> - **Remove from `dockitems_remove`** (keep it in dock) → remove from `dockitems_remove` in `default.config.yml`
> - **Skip** → note in report

### Missing app from Dock (in `dockitems_persist`, not in Dock)
> "**`<AppName>`** should be in your Dock (it's in `dockitems_persist`) but is not currently there."
>
> Options:
> - **Re-apply dock role** → run `ansible-playbook main.yml -i inventory --tags dock`
> - **Remove from `dockitems_persist`** → remove from `dockitems_persist` in `default.config.yml`
> - **Skip** → note in report

Apply the chosen action **immediately** before moving to the next item.

**Note**: After re-applying the dock role, run `killall Dock` to reload the Dock and confirm changes took effect.

---

## Step 5: Verify After Changes

If the dock role was re-applied, re-run the detection command and confirm the Dock now matches `dockitems_persist`:

```bash
defaults read com.apple.dock persistent-apps 2>/dev/null \
  | grep "file-label" \
  | sed 's/.*= "\(.*\)";/\1/'
```

---

## Step 6: Write Drift Report

Write `drift-report-dock.md` to the repo root with:

```markdown
# Drift Report: macOS Dock
Date: <ISO date>

## Resolved
- <AppName>: <action taken>
...

## Skipped
- <AppName>: extra/missing (skipped by user)
...

## No Change Needed
- Count: <n> apps already matched desired state

## Final Dock State
<list of current persistent apps after changes>
```

---

## Files Modified
- `default.config.yml` — if apps were added/removed from `dockitems_persist` or `dockitems_remove`
- `drift-report-dock.md` — written at repo root

## Handoff Notes
- This spec is **fully independent** — can run in parallel with all other specs
- Dock changes take effect immediately after `killall Dock` but may visually reset; this is expected
