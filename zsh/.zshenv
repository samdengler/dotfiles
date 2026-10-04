# Homebrew — must be in .zshenv so it works in non-interactive shells (SSH, scripts)
eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# uv tool install location
export PATH="$HOME/.local/bin:$PATH"
# Rust (rustup installs here; not managed by dotfiles yet, see dotfiles beads)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
