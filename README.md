# Utilisation
```bash
gitdot pull
gitdot status
gitdot add .vimrc
gitdot commit -m "Add vimrc"
gitdot add .bashrc
gitdot commit -m "Add bashrc"
gitdot push
```

# Installation
```bash
wget -O - https://raw.githubusercontent.com/bhanquet/Dotfiles/master/install.sh | bash
```
If we want to edit to add new dotfile it might be necessary to change the url of origin

# Comment faire un nouveau dotfile
``` bash
git init --bare $HOME/.dotfiles.git
```

Pour éviter les loops dans git on peut l'ajouter dans un .gitignore
`echo ".dotfiles.git" >> ~/.gitignore`

Configurer un alias dans le fichier ".bash_aliases"
`alias gitdot='/usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME'`

Cacher les fichiers qui ne sont pas versioné `gitdot config --local status.showUntrackedFiles no`
Ajouter le remote repo
`gitdot remote add origin git@github.com:spli619/Dotfiles.git`
