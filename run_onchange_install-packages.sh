#!/bin/bash
# Installs system packages + fisher + tpm.
# Distro detected via /etc/os-release.
set -euo pipefail

. /etc/os-release
case "${ID:-unknown}" in
  fedora) PKG=dnf ;;
  arch)   PKG=pacman ;;
  debian|ubuntu) PKG=apt ;;
  *) echo "Unsupported distro: '$ID' (expected: fedora, arch, debian, ubuntu)." >&2; exit 1 ;;
esac

have() { command -v "$1" >/dev/null 2>&1; }
warn() { echo "Warning: $*" >&2; }

# chezmoi run_ scripts get a minimal PATH.
export PATH="$HOME/.local/bin:$PATH"

if [[ $EUID -eq 0 ]]; then SUDO=""; else SUDO="sudo"; fi
if [[ $SUDO ]]; then
  have sudo || { echo "sudo required (or run as root)." >&2; exit 1; }
  $SUDO -v
fi

# --- Packages ---
# BASE_PACKAGES = required, fails if any name is missing. OPTIONAL_PACKAGES = silently skipped.
BASE_PACKAGES=(file curl tmux git bat neovim ripgrep fzf fish zoxide luarocks)
case "$PKG" in
  dnf)    BASE_PACKAGES+=(vim-enhanced fd-find) ;;  # Fedora does not ship vim/fd under their usual names.
  pacman) BASE_PACKAGES+=(vim fd) ;;
  apt)    BASE_PACKAGES+=(vim fd-find software-properties-common) ;;  # software-properties-common provides add-apt-repository.
esac
OPTIONAL_PACKAGES=(lazygit)  # Not in Fedora repos; older Debian/Ubuntu may lack it.

refresh() { [[ $PKG == apt ]] && $SUDO env DEBIAN_FRONTEND=noninteractive apt-get update; }

install() {
  case "$PKG" in
    dnf)    $SUDO dnf install -y --refresh "$@" ;;
    pacman) $SUDO pacman -Syu --needed --noconfirm "$@" ;;
    apt)    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
  esac
}

# dnf: --skip-unavailable makes the failure silent. For pacman/apt we let it
# fail and catch with `|| warn`.
install_optional() {
  case "$PKG" in
    dnf)    $SUDO dnf install -y --refresh --skip-unavailable "$@" || warn "unavailable on $ID ${VERSION_ID:-}: $*, skipped." ;;
    pacman) install "$@" || warn "unavailable on $ID ${VERSION_ID:-}: $*, skipped." ;;
    apt)    install "$@" || warn "unavailable on $ID ${VERSION_ID:-}: $*, skipped." ;;
  esac
}

# lazygit is not in Fedora repos → COPR dejan/lazygit.
# `dnf repolist | grep -q` closes the pipe early; dnf5 dies on SIGPIPE; pipefail
# then turns a successful match into a non-zero pipeline and the COPR would be
# re-enabled on every run. Hence the separate capture.
ensure_lazygit_copr() {
  [[ $PKG == dnf ]] || return 0
  dnf repolist 2>/dev/null | grep -q "dejan:lazygit" && return 0
  $SUDO dnf copr enable -y dejan/lazygit || warn "could not enable the lazygit COPR."
}

# Ubuntu/Debian's nvim lags upstream. ppa:neovim-ppa/stable tracks tags that are
# more recent than what the official repos ship. Idempotent: the repo file
# survives across runs, and `add-apt-repository` is a no-op when present.
ensure_neovim_ppa() {
  [[ $PKG == apt ]] || return 0
  grep -Rqs "neovim-ppa" /etc/apt/sources.list.d/ 2>/dev/null && return 0
  $SUDO add-apt-repository -y ppa:neovim-ppa/stable || warn "could not enable the neovim PPA."
}

# On apt, fd is called fdfind and bat is called batcat → shims under ~/.local/bin.
ensure_debian_shims() {
  [[ $PKG == apt ]] || return 0
  mkdir -p "$HOME/.local/bin"
  for pair in "fd:fdfind" "bat:batcat"; do
    link="${pair%%:*}"; target="${pair##*:}"
    have "$link" || have "$target" && ln -sf "$(command -v "$target")" "$HOME/.local/bin/$link"
  done
}

install_fisher() {
  have fish || { echo "fish missing, fisher skipped."; return 0; }
  if ! fish -c 'type -q fisher' >/dev/null 2>&1; then
    fish -c 'curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
  fi
  [[ -f $HOME/.config/fish/fish_plugins ]] && fish -c 'fisher update' || warn "fisher update failed, rerun manually."
}

# Make fish the login shell. Idempotent; warns on failure instead of aborting.
set_default_shell() {
  local user user_shell fish_path
  user=$(id -un)
  # `|| true` so a missing NSS entry doesn't kill the rest of the install.
  user_shell=$(getent passwd "$user" | cut -d: -f7 || true)
  [[ $user_shell == */fish ]] && return 0
  fish_path=$(command -v fish) || return 0
  # chsh refuses paths not listed in /etc/shells.
  grep -qxF "$fish_path" /etc/shells 2>/dev/null || \
    echo "$fish_path" | $SUDO tee -a /etc/shells >/dev/null
  $SUDO chsh -s "$fish_path" "$user" || \
    warn "chsh failed; set fish manually with: chsh -s '$fish_path'"
}

install_tpm() {
  local dir="$HOME/.tmux/plugins/tpm"
  if [[ -d $dir ]]; then
    git -C "$dir" pull --ff-only || warn "TPM update failed."
  else
    git clone --depth 1 https://github.com/tmux-plugins/tpm "$dir"
  fi
  # TMUX_PLUGIN_MANAGER_PATH only exists after the first ~/.tmux.conf is sourced inside tmux.
  if tmux start-server \; show-environment -g TMUX_PLUGIN_MANAGER_PATH 2>/dev/null | grep -q "^TMUX_PLUGIN_MANAGER_PATH="; then
    "$dir/bin/install_plugins" || warn "install_plugins failed; retry with prefix + I inside tmux."
  else
    echo "TPM plugins deferred to first tmux start."
  fi
}

echo "Installing via $PKG ($ID): ${BASE_PACKAGES[*]}"
ensure_lazygit_copr
ensure_neovim_ppa
refresh
install "${BASE_PACKAGES[@]}"

echo "Optional: ${OPTIONAL_PACKAGES[*]}"
install_optional "${OPTIONAL_PACKAGES[@]}"

ensure_debian_shims
install_fisher
set_default_shell
install_tpm

echo "Done. Fish is your login shell; log out and back in (or 'exec fish')."