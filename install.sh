#!/bin/bash -i

echo ".dotfiles.git" >> ~/.gitignore


git clone --bare https://github.com/bhanquet/Dotfiles.git $HOME/.dotfiles.git 2> /dev/null
if [ $? -ne 0 ]; then
	echo "Already installed"
	exit 1
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

source ~/.bashrc
