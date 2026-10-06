# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/). Linux only.

## Install

```bash
sudo apt update && sudo apt install -y curl git   # Fedora: dnf, Arch: pacman
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply bhanquet
```

Then `exec fish` or log out and back in. `--apply` runs
`run_onchange_install-packages.sh`, which installs packages, fisher and tpm.

Supported: **Fedora**, **Arch**, **Debian**, **Ubuntu**. Anything else exits with an
error. Requires `sudo`, or run as root.

## Everyday commands

See <https://www.chezmoi.io/quick-start/>. Shortcuts in fish: `cm` (chezmoi), `cma`
(apply), `cmu` (update), `cmd` (diff), `cms` (status), `cme` (edit).

```bash
chezmoi update
chezmoi diff
```
