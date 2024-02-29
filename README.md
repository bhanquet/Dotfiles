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
# Configurer sur une nouvelle machine
Pour éviter les loops dans git on peut l'ajouter dans un .gitignore
`echo ".dotfiles.git" >> ~/.gitignore`

Configurer un alias dans le fichier ".bash_aliases"
`alias gitdot='/usr/bin/git --git-dir=$HOME/.dotfiles.git --work-tree=$HOME'`
`source .bash_aliases`

``` bash
git clone --bare --depth 1 https://github.com/spli619/Dotfiles.git $HOME/.dotfiles.git
```

>[!Warning]
>Des fichiers de configs pourrais déjà exister sur la machine, il faut donc en faire un backup avant

``` bash
mkdir -p .config-backup && \
config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | \
xargs -I{} mv {} .config-backup/{}

```

Récupère les fichiers du repository.
``` bash
gitdot checkout
gitdot config --local status.showUntrackedFiles no
source .bashrc
```


TODO ajouter l'alias dans .bashrc
```bash
git clone --bare https://bitbucket.org/durdn/cfg.git $HOME/.cfg
function config {
   /usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME $@
}
mkdir -p .config-backup
config checkout
if [ $? = 0 ]; then
  echo "Checked out config.";
  else
    echo "Backing up pre-existing dot files.";
    config checkout 2>&1 | egrep "\s+\." | awk {'print $1'} | xargs -I{} mv {} .config-backup/{}
fi;
config checkout
config config status.showUntrackedFiles no
```
