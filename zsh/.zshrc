# mise (version manager)
eval "$(mise activate zsh)"

# vi keybindings
set -o vi

# treat '#' as a comment in interactive shells
setopt interactive_comments

# aliases
[ -f "$HOME/.zsh_aliases" ] && source "$HOME/.zsh_aliases"
