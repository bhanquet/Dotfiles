#!/bin/bash -i

# Utility Functions
# ==================

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Install packages using the appropriate package manager
install_packages() {
  local packages="$1"
  echo "Installing packages: $packages"

  if command_exists dnf; then
    echo "Detected Fedora. Installing packages..."
    sudo dnf -y groupinstall "Development Tools"
    sudo dnf install -y $packages procps-ng lua luarocks
  elif command_exists pacman; then
    echo "Detected Arch Linux. Installing packages..."
    sudo pacman -Sy --noconfirm $packages base-devel procps-ng lua luarocks
  elif command_exists apt; then
    echo "Detected Debian-based system. Installing packages..."
    sudo apt update && sudo apt install -y $packages build-essential procps lua5.4 luarocks
  else
    echo "Unsupported package manager. This script supports Fedora, Arch, and Debian-based distributions."
    exit 1
  fi
}

# Install Homebrew if not already installed
install_homebrew() {
  if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>~/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  else
    echo "Homebrew is already installed."
  fi
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

# GITDOT Functions
# =================

# Check if GITDOT is installed
is_gitdot_installed() {
  git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME status >/dev/null 2>&1
}

# Set up GITDOT
setup_gitdot() {
  gitdot_() {
    /usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME "$@"
  }

  echo "Setting up GITDOT..."

  git clone --bare https://github.com/bhanquet/Dotfiles.git $HOME/.dotfiles.git || {
    echo "Failed to clone GITDOT repository. Exiting."
    return 1
  }

  # Get the files from the repo. Backup if it already exists
  if ! gitdot_ checkout; then
    echo "Backing up existing dotfiles..."
    mkdir -p .gitdot-backup
    gitdot_ checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} bash -c 'mkdir -p .gitdot-backup/$(dirname {}) && mv {} .gitdot-backup/{}'
    gitdot_ checkout
  fi

  gitdot_ submodule update --init --recursive

  # Git config
  gitdot_ config status.showUntrackedFiles no

  echo "GITDOT setup complete."
}

# Main Script Logic
# ==================

# Install OS Packages
common_packages="file curl vim tmux rsync xclip entr git bat"
install_packages "$common_packages" # Install common packages + basic packages

# Install Homebrew and Brew Packages
install_homebrew
brew_packages=(gcc node neovim ripgrep fd lazygit fzf tre-command)
install_brew_packages "${brew_packages[@]}"

# Install GITDOT if not already installed
if is_gitdot_installed; then
  echo "GITDOT is already installed."
else
  setup_gitdot
fi

# Git Configuration
echo "Setting up Git configuration..."
git config --global user.name "Brian Hanquet"
git config --global user.email "apps.brinat@pm.me"

# Install package manager in tmux
TPM_DIR="$HOME/.tmux/plugins/tpm"

# Check if tpm is already installed
if [ ! -d "$TPM_DIR" ]; then
  echo "TPM not found. Installing..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  "$TPM_DIR/bin/install_plugins"
  echo "TPM installed and plugins initialized."
else
  echo "TPM already installed. Skipping installation."
fi

echo "Setup complete!"
echo "You can type source ~/.bashrc to reload your shell configuration."
