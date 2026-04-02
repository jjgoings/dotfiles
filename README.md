Dotfiles
========

This repo is the source of truth for my shell, terminal, git, tmux, zellij,
Codex CLI defaults, and Vim configuration.

The installer is intentionally narrow:

1. Back up any existing managed targets in `$HOME`
2. Create symlinks from the repo into the right home-directory locations
3. Seed local-only files like `~/.local_zshrc`, `~/.private`, and
   `~/.gitconfig.local` if they do not already exist

It does not install packages, clone shell frameworks, or change your login
shell.

Installation
------------

```bash
git clone https://github.com/jjgoings/dotfiles.git ~/dotfiles
cd ~/dotfiles
./makesymlinks.sh --dry-run
./makesymlinks.sh
```

Useful options:

```bash
./makesymlinks.sh --skip-backup
./makesymlinks.sh --no-local-files
```

Notes
-----

- The repo can live anywhere. `makesymlinks.sh` links from the directory it is
  run from; it does not assume `~/dotfiles`.
- Machine-specific shell config belongs in `~/.local_zshrc`.
- Secrets belong in `~/.private`.
- Codex uses a tracked template at `codex/config.toml.template`. The installer
  bootstraps `~/.codex/config.toml` locally, then refreshes the portable keys
  from the template on later runs while preserving machine-specific state like
  project trust entries.
- Auto-starting `zellij` is gated behind `ENABLE_AUTO_ZELLIJ=1` in
  `~/.local_zshrc`, so carrying the repo to remote machines does not enable it
  by default.

Working with Gaussian DV
-------------

For whatever reason, GDV really only works with C-shell, despite the
`gdv.profile` file. A workaround to load `gdv` and the `mk` aliases is to use
the `c2z` script from this repo. To use, source it in your `~/.local_zshrc`
(should work in bash too), like so:

```bash
. =($HOME/dotfiles/c2z -l)  # adjust if the repo lives elsewhere
```
As long as everything was set up correctly in your old `.tcshrc`, this should
set up most of the necessary gaussian specific environmental variables and 
necessay aliases to do development work.

`zshrc` will look for `~/.local_zshrc` on initialization, so put machine
specific aliases and environmental variables there.

It works by converting the sourced c-shell environmental variables, and
converting the syntax to bourne-shell syntax, which then gets sourced when you
login to zsh or bash. I've found it works for ~95% of the things, so some minor
tweaks may be necessary depending on your machine configuration.
