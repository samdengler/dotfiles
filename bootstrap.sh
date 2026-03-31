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

# 3. Sudoers (allow passwordless sudo for mas)
echo ""
echo "--- Sudoers ---"
MAS_SUDOERS="/etc/sudoers.d/mas"
if [ ! -f "$MAS_SUDOERS" ]; then
    echo "→ Configuring passwordless sudo for mas (requires sudo password once)..."
    echo "$(whoami) ALL=(ALL) NOPASSWD: /opt/homebrew/bin/mas" | sudo tee "$MAS_SUDOERS" > /dev/null
    sudo chmod 440 "$MAS_SUDOERS"
    sudo visudo -cf "$MAS_SUDOERS"
    echo "→ Created $MAS_SUDOERS"
else
    echo "→ $MAS_SUDOERS already exists"
fi

# 4. Brewfile (mas apps require sudo, so install them separately)
echo ""
echo "--- Brew Bundle ---"
MAS_APPS=$(grep '^mas ' "$DOTFILES/Brewfile" | sed 's/.*id: //' || true)
HOMEBREW_BUNDLE_MAS_SKIP="$MAS_APPS" brew bundle --file="$DOTFILES/Brewfile"
if [ -n "$MAS_APPS" ]; then
    echo "→ Installing Mac App Store apps (requires sudo password)..."
    for app_id in $MAS_APPS; do
        sudo mas install "$app_id" || echo "⚠  Failed to install app $app_id — run 'sudo mas install $app_id' manually"
    done
fi

# 5. Git config (before gh auth so credential helpers append to our file)
echo ""
echo "--- Git Config ---"
if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
    echo "→ Backing up existing .gitconfig to .gitconfig.bak"
    cp "$HOME/.gitconfig" "$HOME/.gitconfig.bak"
fi
ln -sf "$DOTFILES/git/gitconfig" "$HOME/.gitconfig"
echo "→ Linked .gitconfig"

# 6. GitHub CLI
echo ""
echo "--- GitHub CLI ---"
gh auth setup-git
echo "→ Configured git credential helper"

# 7. Shell config (symlink — re-running just overwrites the same link)
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

# 8. Ghostty
echo ""
echo "--- Ghostty ---"
if [ -d "$HOME/.config/ghostty" ] && [ ! -L "$HOME/.config/ghostty" ]; then
    echo "→ Backing up existing ghostty config to ghostty.bak"
    mv "$HOME/.config/ghostty" "$HOME/.config/ghostty.bak"
fi
mkdir -p "$HOME/.config"
ln -sf "$DOTFILES/ghostty" "$HOME/.config/ghostty"
echo "→ Linked ghostty config"

# 9. Claude Code
echo ""
echo "--- Claude Code ---"
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/settings.json" ] && [ ! -L "$HOME/.claude/settings.json" ]; then
    echo "→ Backing up existing settings.json to settings.json.bak"
    cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.bak"
fi
ln -sf "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
echo "→ Linked Claude Code settings.json"
# Patch ~/.claude.json preferences (vim mode, remote control)
CLAUDE_JSON="$HOME/.claude.json"
if [ -f "$CLAUDE_JSON" ]; then
    jq '.editorMode = "vim" | .remoteControlAtStartup = true' "$CLAUDE_JSON" > "${CLAUDE_JSON}.tmp" \
        && mv "${CLAUDE_JSON}.tmp" "$CLAUDE_JSON"
else
    echo '{"editorMode":"vim","remoteControlAtStartup":true}' > "$CLAUDE_JSON"
fi
echo "→ Set vim mode and remote control in claude.json"

# 10. Alfred (point preferences to dotfiles)
echo ""
echo "--- Alfred ---"
ALFRED_PREFS_JSON="$HOME/Library/Application Support/Alfred/prefs.json"
ALFRED_TARGET="$DOTFILES/alfred"
if [ -f "$ALFRED_PREFS_JSON" ]; then
    CURRENT=$(python3 -c "import json; print(json.load(open('$ALFRED_PREFS_JSON'))['current'])" 2>/dev/null || true)
    if [ "$CURRENT" != "$ALFRED_TARGET" ]; then
        jq --arg path "$ALFRED_TARGET" '.current = $path' "$ALFRED_PREFS_JSON" > "${ALFRED_PREFS_JSON}.tmp" \
            && mv "${ALFRED_PREFS_JSON}.tmp" "$ALFRED_PREFS_JSON"
        echo "→ Pointed Alfred preferences to $ALFRED_TARGET"
    else
        echo "→ Alfred already using dotfiles preferences"
    fi
else
    echo "→ Alfred not installed yet, skipping"
fi

# 11. App settings
echo ""
echo "--- App Settings ---"
echo "→ Importing Rectangle Pro settings..."
defaults import com.knollsoft.Hookshot "$DOTFILES/rectangle-pro/settings.plist"

# 12. mise
echo ""
echo "--- mise ---"
mkdir -p "$HOME/.config/mise"
if [ -f "$HOME/.config/mise/config.toml" ] && [ ! -L "$HOME/.config/mise/config.toml" ]; then
    echo "→ Backing up existing mise config.toml to config.toml.bak"
    cp "$HOME/.config/mise/config.toml" "$HOME/.config/mise/config.toml.bak"
fi
ln -sf "$DOTFILES/mise/config.toml" "$HOME/.config/mise/config.toml"
echo "→ Linked mise config.toml"
eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(mise activate bash)"
mise install
echo "→ mise tools installed"

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
echo " 10. System Settings > Internet Accounts > add Google account for Calendar"
echo " 11. Messages > Settings > uncheck 'Play sound effects'"
echo " 12. Restart your terminal to pick up shell config"
