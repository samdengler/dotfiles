# dotfiles

Mac setup, automated.

## Fresh machine

```bash
git clone https://github.com/samdengler/dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

`bootstrap.sh` is idempotent — safe to re-run anytime.

## Updating app settings

After changing settings in apps that are tracked here, re-export them:

```bash
# Rectangle Pro
defaults export com.knollsoft.Hookshot ~/.dotfiles/rectangle-pro/settings.plist
```

Then commit and push.

## What's in here

| Path | What |
|---|---|
| `bootstrap.sh` | Single entry point — runs everything |
| `Brewfile` | Homebrew packages and casks |
| `macos/defaults.sh` | System preferences (scroll, caps lock, spotlight, dock) |
| `zsh/.zshenv` | Homebrew PATH (all shells) |
| `zsh/.zshrc` | mise + vi keybindings (interactive shells) |
| `rectangle-pro/settings.plist` | Window management shortcuts and layouts |

## Manual steps (after bootstrap)

1. Open 1Password and sign in
2. Install 1Password Safari extension (App Store)
3. Safari > Settings > AutoFill > uncheck "Usernames and passwords"
4. Safari > Settings > Extensions > disable "Passwords"
5. Open Rectangle Pro, activate license
6. Open Alfred, set Cmd+Space as hotkey
7. Open Tailscale, sign in
8. Run `claude` to authenticate Claude Code
9. Restart your terminal
