#!/bin/bash
# Bootstrap a fresh Mac from scratch.
# Usage: git clone https://github.com/samdengler/dotfiles.git ~/.dotfiles && ~/.dotfiles/bootstrap.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "=== Bootstrap ==="

# 1. macOS defaults (no dependencies)
echo ""
echo "--- macOS Defaults ---"
bash "$DOTFILES/macos/defaults.sh"

# 2. Homebrew
echo ""
echo "--- Homebrew ---"
if ! command -v brew &>/dev/null; then
    echo "→ Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "→ Homebrew already installed"
fi

# 3. Brewfile
echo ""
echo "--- Brew Bundle ---"
brew bundle --file="$DOTFILES/Brewfile"

# 4. Shell config
echo ""
echo "--- Shell Config ---"
for file in .zshenv .zshrc; do
    src="$DOTFILES/zsh/$file"
    dst="$HOME/$file"
    if [ -f "$dst" ]; then
        echo "→ Backing up existing $file to ${file}.bak"
        cp "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    echo "→ Linked $file"
done

# 5. mise
echo ""
echo "--- mise ---"
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(mise activate bash)"
mise use --global node@24
echo "→ Node $(node -v) installed"

echo ""
echo "=== Bootstrap complete ==="
echo ""
echo "Next steps:"
echo "  1. Open 1Password and sign in"
echo "  2. Install 1Password Safari extension (App Store)"
echo "  3. Open Alfred, set Cmd+Space as hotkey"
echo "  4. Open Tailscale, sign in"
echo "  5. Run 'claude' to authenticate Claude Code"
echo "  6. Restart your terminal to pick up shell config"
