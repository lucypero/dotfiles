---
name: sync-dotfiles
description: Keep this dotfiles repo, the live configs on this machine, and GitHub in sync. Use whenever you edit, add or remove any config tracked in this repo (Zed, Nushell, WezTerm, mpv, Sublime Merge, or anything in dotfiles.json), and when the user says "sync", "save my configs" or "push my dotfiles". After every such change, the change must be live on this machine, committed, and pushed.
---

# Sync dotfiles

The repo holds copies of configs, and `dot.py` copies them between the repo and
this machine. The apps read only the copy on the machine (for example
`%APPDATA%\nushell\config.nu`), not the repo file. So an edit in the repo does
nothing until it is applied, and an edit made on the machine (such as through
Zed's settings UI) is not in the repo until it is saved.

Use `python3`, not `python` (on Windows `python` may be Python 2). Run commands
from the repo root.

## 1. Before editing: pick up changes from the machine

```powershell
python3 dot.py status
```

If a config you are about to touch shows differences, run
`python3 dot.py diff <name>` and look at them. Changes made on the machine are
usually the user's own recent choices (a theme switch, a new setting), so save
them into the repo with `python3 dot.py save <name>` before editing. Otherwise,
applying your edit later would overwrite them. If a machine change looks
accidental or you can't tell, ask the user.

## 2. Edit the repo copy

Make the change in the repo folder (`nushell/`, `zed/`, ...), never in the
machine copy. To track a new config, use `python3 dot.py add` (see README.md).

## 3. Apply it to this machine

```powershell
python3 dot.py apply <name> --dry-run
python3 dot.py apply <name>
```

Apply only the configs you changed. `apply` backs up overwritten files to
`~/.dotfiles-backup/<timestamp>/`. Then confirm `python3 dot.py status` reports
every config `in sync`.

Check the change on the live copy, not the repo copy. For Nushell, `nu -c`
does not load the config files, so pass them in:

```powershell
nu --env-config "$env:APPDATA\nushell\env.nu" --config "$env:APPDATA\nushell\config.nu" -c '<check>'
```

Running apps keep the old config until restarted (a new Zed terminal tab, a new
WezTerm window, and so on). Tell the user what to reopen.

## 4. Commit and push

Commit everything the sync touched, including files saved from the machine in
step 1, then push:

```powershell
git add -A
git commit -m "<message>"
git push
```

Message style (same as `zed/AGENTS.md`): a capitalized subject in the
imperative, about 50 characters at most, with no trailing period. Add a short
body only if it says something useful. If the push fails (no network, rejected),
report it and don't force-push.

## Done when

- `python3 dot.py status` shows every config `in sync`.
- `git status` is clean and the branch is not ahead of `origin`.
