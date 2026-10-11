# dotfiles

My dev configs: Zed, Nushell, WezTerm, mpv, Sublime Merge.

Each config lives in its own folder here. `dotfiles.json` says where it goes on
each OS (Windows / Linux / macOS). `dot.py` copies files between the system and
the repo, and needs only the Python 3 standard library.

On Windows, `python` may point at Python 2. If it does, use `py -3` or `python3`.

## New machine

```sh
git clone https://github.com/lucypero/dotfiles ~/dotfiles
cd ~/dotfiles
python3 dot.py apply --dry-run   # see what would change
python3 dot.py apply
```

Install the apps before or after, in either order. On Windows, mpv and Sublime
Merge are expected to be installed with scoop, so their configs go in
`~/scoop/persist/...`. Scoop picks them up when it installs the app.

`apply` backs up every file it overwrites to `~/.dotfiles-backup/<timestamp>/`.

## Day to day

```sh
python3 dot.py status            # what changed on this machine?
python3 dot.py diff zed          # show the actual changes
python3 dot.py save              # copy system configs into the repo
git commit -am "..." && git push
```

## Tracking something new

```sh
python3 dot.py add helix ~/AppData/Roaming/helix -i config.toml -i languages.toml
python3 dot.py add gitconfig ~/.gitconfig
```

This records the path for the current OS in `dotfiles.json` and saves the
files. To use the config on another OS, add that OS's path to `dotfiles.json`
by hand.
