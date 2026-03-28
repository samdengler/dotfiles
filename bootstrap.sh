#!/bin/bash
# Bootstrap a fresh Mac from scratch. Safe to run multiple times (idempotent).
# Usage: git clone https://github.com/samdengler/dotfiles.git ~/.dotfiles && ~/.dotfiles/bootstrap.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "=== Bootstrap ==="

# 1. macOS defaults
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

# 4. GitHub CLI
echo ""
echo "--- GitHub CLI ---"
gh auth setup-git
echo "→ Configured git credential helper"

# 5. Shell config (symlink — re-running just overwrites the same link)
echo ""
echo "--- Shell Config ---"
for file in .zshenv .zshrc; do
    src="$DOTFILES/zsh/$file"
    dst="$HOME/$file"
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
        echo "→ Backing up existing $file to ${file}.bak"
        cp "$dst" "${dst}.bak"
    fi
    ln -sf "$src" "$dst"
    echo "→ Linked $file"
done

# 6. Ghostty
echo ""
echo "--- Ghostty ---"
if [ -d "$HOME/.config/ghostty" ] && [ ! -L "$HOME/.config/ghostty" ]; then
    echo "→ Backing up existing ghostty config to ghostty.bak"
    mv "$HOME/.config/ghostty" "$HOME/.config/ghostty.bak"
fi
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES/ghostty" "$HOME/.config/ghostty"
echo "→ Linked ghostty config"

# 7. App settings
echo ""
echo "--- App Settings ---"
echo "→ Importing Rectangle Pro settings..."
defaults import com.knollsoft.Hookshot "$DOTFILES/rectangle-pro/settings.plist"

# 8. mise
echo ""
echo "--- mise ---"
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(mise activate bash)"
mise use --global node@24
echo "→ Node $(node -v) installed"

echo ""
echo "=== Bootstrap complete ==="
echo ""
echo "Manual steps:"
echo "  1. Open 1Password and sign in"
echo "  2. Install 1Password Safari extension (App Store)"
echo "  3. Safari > Settings > AutoFill > uncheck 'Usernames and passwords'"
echo "  4. Safari > Settings > Extensions > disable 'Passwords'"
echo "  5. Open Rectangle Pro, activate license"
echo "  6. Open Alfred, set Cmd+Space as hotkey"
echo "  7. Open Tailscale, sign in"
echo "  8. Run 'gh auth login' to authenticate GitHub CLI"
echo "  9. Run 'claude' to authenticate Claude Code"
echo " 10. Restart your terminal to pick up shell config"
