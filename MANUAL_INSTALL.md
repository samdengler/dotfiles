# Manual install (no-admin branch)

This branch is for setting up a Mac that does **not** yet have admin access (so Homebrew can't be installed). Once IT grants admin, switch back to `master` and re-run `bootstrap.sh` to converge on the canonical, brew-managed setup.

## Order of operations

1. Install the GUI apps from the vendor links below.
2. Run `~/.dotfiles/bootstrap.sh` — installs user-space CLI tools (uv, mise, ruff, gh, bd) into `~/.local/bin`, runs the no-sudo subset of `macos/defaults.sh`, and creates all the dotfile symlinks.
3. Install Mac App Store apps from the App Store UI.
4. Install awscli + dolt manually (links below).
5. Run the post-bootstrap "Manual steps" that `bootstrap.sh` prints.

> **Note:** 1Password, Tailscale, and Jump Desktop are intentionally omitted on this branch — not needed/available on the work machine. You'll log into `gh`, `claude`, Discord, etc. with credentials from your work password manager / iCloud Keychain / manual entry.

## GUI apps — download from vendor

| App | Download |
|---|---|
| Google Chrome | https://www.google.com/chrome/ |
| Ghostty | https://ghostty.org/download |
| Alfred | https://www.alfredapp.com/ |
| Claude (desktop) | https://claude.ai/download |
| Claude Code | https://claude.com/claude-code (or `npm i -g @anthropic-ai/claude-code` once `mise` provides node) |
| Rectangle Pro | https://rectangleapp.com/pro |
| Visual Studio Code | https://code.visualstudio.com/Download |
| Discord | https://discord.com/download |
| Snagit | https://www.techsmith.com/screen-capture.html |

## Mac App Store

Open the App Store and search for:

- **Mimestream**

(`mas` itself is not installable without Homebrew; install via the App Store UI on this branch.)

## CLI tools — auto-installed by `bootstrap.sh`

These land in `~/.local/bin` (no admin needed). No action required — listed for reference:

- `uv` — `curl -LsSf https://astral.sh/uv/install.sh | sh`
- `mise` — `curl -fsSL https://mise.run | sh`
- `ruff` — `uv tool install ruff`
- `gh` — extracted from the latest GitHub release for `cli/cli`
- `bd` (beads) — extracted from the latest GitHub release for `steveyegge/beads`

## CLI tools — manual install

Both of these have installers that want admin / `sudo`. Install by hand to `~/.local/bin`.

**awscli** — official docs: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html. Easiest no-admin path:

```sh
uv tool install awscli
```

**dolt** — download the macOS tarball from https://github.com/dolthub/dolt/releases/latest, then:

```sh
tar -xzf dolt-darwin-arm64.tar.gz
install dolt-darwin-arm64/bin/dolt ~/.local/bin/dolt
```

## Switching back to `master` (once admin is granted)

```sh
git checkout master
~/.dotfiles/bootstrap.sh
```

This installs Homebrew, runs `brew bundle`, and re-applies `macos/defaults.sh` with sudo (so Touch ID + display-sleep settings finally take effect).

The `~/.local/bin` shims are harmless — Homebrew's `/opt/homebrew/bin` comes first on `PATH` via `master`'s `.zshenv`, so brew versions win. Optional cleanup if you want a tidy `~/.local/bin`:

```sh
rm -f ~/.local/bin/{uv,mise,gh,bd}
uv tool uninstall ruff
```
