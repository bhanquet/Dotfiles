if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Homebrew (équivalent de `eval "$(brew shellenv)"`)
if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# zoxide (smarter cd)
zoxide init fish | source

# Chemins prioritaires (prepend)
fish_add_path -m /home/brian/.opencode/bin
fish_add_path -m /home/brian/.local/bin
fish_add_path -m /home/brian/.local/share/pnpm
fish_add_path -m /home/brian/bin

set -U fish_greeting ""

# Aliases & functions

alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gp='git push'
alias gd='git diff'
alias lg='lazygit'

alias cm='chezmoi'
alias cma='chezmoi apply'
alias cmu='chezmoi update'
alias cmd='chezmoi diff'
alias cms='chezmoi status'
alias cme='chezmoi edit'

alias t='tmux'
alias ta='tmux attach'
alias tls='tmux ls'
alias tk='tmux kill-server'

alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias di='docker images'

function dlogs
    docker logs -f $argv
end

# Neovim
alias v='nvim'
## Ouvrir un projet dans nvim
function vp
    set dir (fd . ~/projects -d 1 -t d | xargs -n1 basename | fzf)

    test -n "$dir"; and nvim ~/projects/$dir
end

## Ouvrir un fichier dans nvim
function vf
    set file (fd . -t f | fzf)

    test -n "$file"; and nvim "$file"
end

alias reload='source ~/.config/fish/config.fish'
