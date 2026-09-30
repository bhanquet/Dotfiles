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
