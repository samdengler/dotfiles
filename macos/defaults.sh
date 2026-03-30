#!/bin/bash
# macOS system preferences — safe to run multiple times (idempotent)
set -euo pipefail

echo "=== macOS Defaults ==="

# Disable natural scroll direction (use traditional scrolling)
echo "→ Disabling natural scroll direction..."
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Remap Caps Lock → Control (persistent via LaunchAgent)
echo "→ Remapping Caps Lock to Control..."
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/com.local.KeyRemapping.plist"

mkdir -p "$PLIST_DIR"
cat > "$PLIST_FILE" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.KeyRemapping</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST

/usr/bin/hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}' > /dev/null
launchctl bootout gui/$(id -u) "$PLIST_FILE" 2>/dev/null || true
launchctl bootstrap gui/$(id -u) "$PLIST_FILE"

# Fast key repeat (lower = faster; defaults are 6/25)
echo "→ Setting fast key repeat..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable Spotlight Cmd+Space (free it for Alfred)
echo "→ Disabling Spotlight Cmd+Space..."
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '
<dict>
    <key>enabled</key>
    <false/>
    <key>value</key>
    <dict>
        <key>parameters</key>
        <array>
            <integer>65535</integer>
            <integer>49</integer>
            <integer>1048576</integer>
        </array>
        <key>type</key>
        <string>standard</string>
    </dict>
</dict>'
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u

# Mouse: enable right-click (click right side)
echo "→ Enabling mouse right-click..."
defaults write com.apple.AppleMultitouchMouse MouseButtonMode -string TwoButton
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string TwoButton
defaults write com.apple.AppleMultitouchMouse MouseButtonDivision -int 55
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonDivision -int 55

# Dock: clear icons, auto-hide, no recents, icon size 44
echo "→ Configuring Dock..."
defaults write com.apple.dock persistent-apps -array
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock tilesize -int 44
killall Dock

# Finder: list view by default
echo "→ Configuring Finder..."
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
killall Finder

# Screenshots: save to ~/Screenshots instead of Desktop
echo "→ Setting screenshot location..."
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

echo "✓ Done"
