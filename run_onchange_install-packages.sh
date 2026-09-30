#!/bin/bash
set -euo pipefail

# Utility Functions
# ==================

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Install packages using the appropriate package manager
install_packages() {
  local packages=("$@")
  echo "Installing packages: ${packages[*]}"

  if command_exists dnf; then
    echo "Detected Fedora. Installing packages..."
    sudo dnf -y group install "Development Tools"
    sudo dnf install -y "${packages[@]}" procps-ng lua luarocks
  elif command_exists pacman; then
    echo "Detected Arch Linux. Installing packages..."
    sudo pacman -Sy --noconfirm --needed "${packages[@]}" base-devel procps-ng lua luarocks
  elif command_exists apt; then
    echo "Detected Debian-based system. Installing packages..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}" build-essential procps lua5.4 luarocks
  else
    echo "Unsupported package manager. This script supports Fedora, Arch, and Debian-based distributions."
    exit 1
  fi
}

# Install Homebrew if not already installed
install_homebrew() {
  local brew_path=""

  # Look for an existing brew installation in PATH or at known locations
  if command_exists brew; then
    brew_path="$(command -v brew)"
  else
    for candidate in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew" /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [ -x "$candidate" ]; then
        brew_path="$candidate"
        break
      fi
    done
  fi

  # Install if not found anywhere
  if [ -z "$brew_path" ]; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for candidate in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew" /opt/homebrew/bin/brew /usr/local/bin/brew; do
      if [ -x "$candidate" ]; then
        brew_path="$candidate"
        break
      fi
    done
    if [ -z "$brew_path" ]; then
      echo "ERROR: brew binary not found after installation." >&2
      exit 1
    fi
    echo "Homebrew installed at $brew_path"
  else
    echo "Homebrew is already installed at $brew_path"
  fi

  # Ensure brew is available in the current shell.
  eval "$("$brew_path" shellenv)"
}

# Install Homebrew packages
install_brew_packages() {
  local brew_packages=("$@")
  echo "Installing Homebrew packages: ${brew_packages[*]}"
  for pkg in "${brew_packages[@]}"; do
    if brew list "$pkg" >/dev/null 2>&1; then
      echo "$pkg is already installed."
    else
      brew install "$pkg"
    fi
  done
}

# Install Fisher (fish plugin manager) and let it pick up the plugins listed
# in the chezmoi-managed ~/.config/fish/fish_plugins. Idempotent.
install_fisher() {
  if ! command_exists fish; then
    echo "Fish is not installed yet; skipping fisher install."
    return
  fi

  if fish -c 'type -q fisher' >/dev/null 2>&1; then
    echo "Fisher is already installed; updating plugins from fish_plugins."
    fish -c 'fisher update' || echo "Warning: fisher update failed (run 'fisher update' manually)."
  else
    echo "Installing Fisher (fish plugin manager)..."
    fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'
    echo "Installing plugins from fish_plugins..."
    fish -c 'fisher update' || echo "Warning: fisher update failed (run 'fisher update' manually)."
  fi
}

# Main Script Logic
# ==================

# Pre-flight: required tools
command_exists sudo || {
  echo "sudo is required" >&2
  exit 1
}
command_exists curl || {
  echo "curl is required for Homebrew" >&2
  exit 1
}
command_exists git || {
  echo "git is required" >&2
  exit 1
}
sudo -v

# Install OS packages
common_packages=(file curl vim tmux rsync xclip entr git bat)
install_packages "${common_packages[@]}"

# Install Homebrew and Brew packages
install_homebrew
brew_packages=(gcc node neovim ripgrep fd lazygit fzf tre-command rtk fish zoxide)
install_brew_packages "${brew_packages[@]}"

# Install Fisher (fish plugins)
install_fisher

# Install TPM (Tmux Plugin Manager)
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
  echo "TPM not found. Installing..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  "$TPM_DIR/bin/install_plugins" || echo "Warning: TPM plugin install failed (run manually inside tmux: prefix + I)"
  echo "TPM installed and plugins initialized."
else
  echo "TPM already installed. Skipping installation."
fi

echo "Setup complete!"
echo "Fish is your default shell. Open a new terminal session (or run 'exec fish') to start using it."
