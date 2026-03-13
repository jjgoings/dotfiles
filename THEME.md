# Theme Reference

Current terminal and shell color scheme reference for this repo.

## Terminal

Default iTerm2 profile:

- Background: `#2b2d31`
- Foreground: `#e2d8d4`
- Bold: `#f3ece8`
- Cursor: `#ddd3cf`
- Selection: `#5a5058`

ANSI palette:

- `0-7`: `#85777f` `#ef6f79` `#a8d787` `#ffd37f` `#78a9ff` `#c792ea` `#a0a8c0` `#ddd3cf`
- `8-15`: `#988890` `#ff7f8a` `#b7e395` `#ffe29c` `#8db9ff` `#d4a6f4` `#b0b8d0` `#f6efea`

## Prompt

Defined in `starship.toml`.

- Env: red `#ff6b6b`
- Username: orange `#ff9f43`
- Hostname: gold `#ffd166`
- Path: green `#98c379`
- Git branch: blue `#5ea1ff`
- Success prompt: green `#98c379`
- Error prompt: red `#ff6b6b`

Prompt shape:

```text
(env) user@host:path <branch> $
```

## Shell Syntax

Defined in `zshrc`.

- Valid commands: green
- Precommands like `sudo`: purple
- Paths and autodirectory targets: olive
- Unknown commands: red
- Reserved words and globbing: soft blue
- Strings: warm gold
- Flags: gray
- Comments and autosuggestions: dim gray

## File Listings

Defined in `LS_COLORS` and `LSCOLORS`.

- Directories: muted slate blue
- Symlinks: mauve
- Executables: bold green
- Regular files: default foreground

This is intentionally restrained. The prompt carries semantic color; `ls` output does not try to classify every file type.

## FZF

- Highlight and marker: `#c792ea`
- Prompt: `#5ea1ff`
- Pointer: `#ff6b6b`
- Spinner: `#98c379`

## Zellij

Defined in `zellij/config.kdl`.

- Foreground: `#d8dee9`
- Background: `#1c1f26`
- Red: `#ff6b6b`
- Green: `#98c379`
- Yellow: `#ffd166`
- Blue: `#5ea1ff`
- Magenta: `#c792ea`
- Cyan: `#a0a8c0`
- Orange: `#ff9f43`
- White: `#eef2ff`
- Black: `#353b45`

Behavior notes:

- `simplified_ui true`
- `scroll_buffer_size 100000`
- `serialize_pane_viewport false`

Zellij config may exist on remote machines via the dotfiles repo, but auto-attach is gated behind `ENABLE_AUTO_ZELLIJ=1` in machine-local shell config.

## Vim

Uses `tokyonight-night` with local overrides in `vimrc` plus a patched `vim-airline` palette.

- Background: `#2b2d31`
- Sidebar and float background: `#24262a`
- Highlight background: `#33353a`
- Comments: `#85777f`, italic
- Punctuation and operators: dimmed to the comment gray family
- Types: softened blue, no bold
- Keywords, functions, strings, and constants: `tokyonight` defaults

Airline mode colors map to the shell prompt semantics:

- Normal: green `#98c379`
- Insert: orange `#ff9f43`
- Visual: blue `#5ea1ff`
- Replace: red `#ff6b6b`
- Command: purple `#c792ea`

ALE has been removed. The statusline now shows mode, branch, filename, and ASCII cursor position without linter sections.
