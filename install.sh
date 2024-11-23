#!/bin/bash -i

# Install GITDOT
# ====================

echo ".dotfiles.git" >> ~/.gitignore


git clone --bare https://github.com/bhanquet/Dotfiles.git $HOME/.dotfiles.git 2> /dev/null
if [ $? -ne 0 ]; then
	echo "Already installed"
fi;

function gitdot {
    /usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME $@
}

gitdot checkout 2> /dev/null
if [ $? = 0 ]; then
    echo "Checked out config.";
    else
      mkdir -p .gitdot-backup
      echo "Backing up pre-existing dot files.";
      gitdot checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} bash -c 'mkdir -p .gitdot-backup/$(dirname {}) && mv {} .gitdot-backup/{}'
      gitdot checkout
fi;

gitdot config status.showUntrackedFiles no

# Install usefull app
# ======================

# Define the packages to install
PACKAGES="build-essential vim tmux rsync xclip git"

# Detect the package manager and install packages
if command -v dnf >/dev/null 2>&1; then
    echo "Detected Fedora. Installing packages..."
    sudo dnf install -y $PACKAGES
elif command -v pacman >/dev/null 2>&1; then
    echo "Detected Arch Linux. Installing packages..."
    sudo pacman -Sy --noconfirm $PACKAGES
elif command -v apt >/dev/null 2>&1; then
    echo "Detected Debian-based system. Installing packages..."
    sudo apt update && sudo apt install -y $PACKAGES
else
    echo "Unsupported package manager. This script supports Fedora, Arch, and Debian-based distributions."
    exit 1
fi

# Confirm installation
echo "Installation complete. Checking versions of installed packages:"


# Install Homebrew if not already installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo >> $HOME/.bashrc
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.bashrc
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
    echo "Homebrew is already installed."
fi

# Update Homebrew
echo "Updating Homebrew..."
brew update

# Install missing apps using Homebrew
BREW_PACKAGES="gcc neovim ripgrep lazygit fzf tre-command"
echo "Installing applications via Homebrew..."
brew install $BREW_PACKAGES


# App configuration
# ======================

# Git
git config --global user.name "Brian Hanquet"
git config --global user.email "apps.brinat@pm.me"

source ~/.bashrc
