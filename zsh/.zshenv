# User-space binaries (no-admin branch installs uv/mise/gh/bd/ruff here)
export PATH="$HOME/.local/bin:$PATH"

# TinyTeX (xelatex, pdflatex, etc.)
export PATH="$PATH:$HOME/Library/TinyTeX/bin/universal-darwin"

# Homebrew — only if installed (skipped on the no-admin branch until admin is granted)
if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi
