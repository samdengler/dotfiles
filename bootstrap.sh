#!/bin/bash
# Bootstrap a fresh Mac from scratch. Safe to run multiple times (idempotent).
# Usage: git clone https://github.com/samdengler/dotfiles.git ~/.dotfiles && ~/.dotfiles/bootstrap.sh
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

echo "=== Bootstrap ==="

# 1. macOS defaults (NO_SUDO=1 skips sudo-required blocks; this branch has no admin)
echo ""
echo "--- macOS Defaults ---"
NO_SUDO=1 bash "$DOTFILES/macos/defaults.sh"

# 2. User-space CLI tools (no Homebrew on this branch — see MANUAL_INSTALL.md)
echo ""
echo "--- User-Space CLI Tools ---"
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

if ! command -v uv &>/dev/null; then
    echo "→ Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo "→ uv already installed"
fi

if ! command -v mise &>/dev/null; then
    echo "→ Installing mise..."
    curl -fsSL https://mise.run | sh
else
    echo "→ mise already installed"
fi

if ! command -v ruff &>/dev/null; then
    echo "→ Installing ruff via uv..."
    uv tool install ruff
else
    echo "→ ruff already installed"
fi

if ! command -v gh &>/dev/null; then
    echo "→ Installing gh..."
    GH_ARCH=$(uname -m)
    [ "$GH_ARCH" = "arm64" ] && GH_ARCH=arm64 || GH_ARCH=amd64
    GH_TARBALL=$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest \
        | grep "browser_download_url.*macOS_${GH_ARCH}.zip" \
        | head -n1 | cut -d'"' -f4)
    GH_TMP=$(mktemp -d)
    curl -fsSL "$GH_TARBALL" -o "$GH_TMP/gh.zip"
    unzip -q "$GH_TMP/gh.zip" -d "$GH_TMP"
    install "$GH_TMP"/gh_*/bin/gh "$HOME/.local/bin/gh"
    rm -rf "$GH_TMP"
else
    echo "→ gh already installed"
fi

if ! command -v bd &>/dev/null; then
    echo "→ Installing bd (beads)..."
    BD_ARCH=$(uname -m)
    BD_URL=$(curl -fsSL https://api.github.com/repos/steveyegge/beads/releases/latest \
        | grep "browser_download_url.*darwin.*${BD_ARCH}" \
        | head -n1 | cut -d'"' -f4)
    if [ -z "$BD_URL" ]; then
        echo "⚠  Could not find a darwin/${BD_ARCH} bd release asset — install manually from https://github.com/steveyegge/beads/releases"
    else
        BD_TMP=$(mktemp -d)
        case "$BD_URL" in
            *.tar.gz|*.tgz)
                curl -fsSL "$BD_URL" -o "$BD_TMP/bd.tgz"
                tar -xzf "$BD_TMP/bd.tgz" -C "$BD_TMP"
                install "$(find "$BD_TMP" -name bd -type f | head -n1)" "$HOME/.local/bin/bd"
                ;;
            *.zip)
                curl -fsSL "$BD_URL" -o "$BD_TMP/bd.zip"
                unzip -q "$BD_TMP/bd.zip" -d "$BD_TMP"
                install "$(find "$BD_TMP" -name bd -type f | head -n1)" "$HOME/.local/bin/bd"
                ;;
            *)
                curl -fsSL "$BD_URL" -o "$HOME/.local/bin/bd"
                chmod +x "$HOME/.local/bin/bd"
                ;;
        esac
        rm -rf "$BD_TMP"
    fi
else
    echo "→ bd already installed"
fi

echo "→ See MANUAL_INSTALL.md for awscli, dolt, GUI apps, and Mac App Store apps."

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
export PATH="$HOME/.local/bin:$PATH"
eval "$(mise activate bash)"
mise install
echo "→ mise tools installed"

echo ""
echo "=== Bootstrap complete ==="
echo ""
echo "Manual steps:"
echo "  1. Install GUI apps + awscli/dolt/Mimestream per MANUAL_INSTALL.md (if not done)"
echo "  2. Open 1Password and sign in"
echo "  3. Install 1Password Safari extension (App Store)"
echo "  4. Safari > Settings > AutoFill > uncheck 'Usernames and passwords'"
echo "  5. Safari > Settings > Extensions > disable 'Passwords'"
echo "  6. Open Rectangle Pro, activate license"
echo "  7. Open Alfred, set Cmd+Space as hotkey"
echo "  8. Open Tailscale, sign in"
echo "  9. Run 'gh auth login' to authenticate GitHub CLI"
echo " 10. Run 'claude' to authenticate Claude Code"
echo " 11. System Settings > Internet Accounts > add Google account for Calendar"
echo " 12. Messages > Settings > uncheck 'Play sound effects'"
echo " 13. Restart your terminal to pick up shell config"
echo ""
echo "Once admin is granted, switch back: git checkout master && ~/.dotfiles/bootstrap.sh"
