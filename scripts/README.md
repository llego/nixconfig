# NixConfig Scripts

Helper scripts for managing the NixOS configuration repository.

## supermemory-post-commit.sh

Git post-commit hook that automatically logs configuration changes to supermemory.

### Features
- **Automatic tracking**: Runs after every commit
- **Host detection**: Identifies which hosts are affected by file changes
- **Categorization**: Classifies changes as add/remove/fix/update/docs/etc.
- **Documentation tracking**: Special handling for README.md and AGENTS.md updates
- **Local backup**: Also logs to `.nixconfig-changes/` as fallback

### Installation
```bash
# The hook is automatically installed when you clone the repo
# Manual install:
cp scripts/supermemory-post-commit.sh .git/hooks/post-commit
chmod +x .git/hooks/post-commit
```

### How it works
After each commit, the hook:
1. Extracts commit hash, message, and changed files
2. Detects affected hosts from file paths (hosts/laptop/*, modules/core/*, etc.)
3. Categorizes the change based on commit message keywords
4. Stores structured data in supermemory (user scope)
5. Creates a local backup log in `.nixconfig-changes/`

### Storage Format
```
NIXCONFIG CHANGE: [2026-04-03] crisuflix - add

COMMIT: 551dd38
MESSAGE: "add home-assistant integration"

AFFECTED HOSTS: crisuflix
CATEGORY: add
FILES: modules/home-automation.nix, hosts/crisuflix/default.nix

SUMMARY:
[Full commit message]
```

## nixconfig-history

CLI tool for querying configuration change history.

### Usage

```bash
# Show changes for specific host
nixconfig-history host crisuflix

# Show changes by category
nixconfig-history category add
nixconfig-history category fix

# Show recent changes
nixconfig-history recent          # Last 10
nixconfig-history recent 20       # Last 20

# Show documentation updates
nixconfig-history docs

# Search for specific term
nixconfig-history search "traefik"
nixconfig-history search "secret"

# Show statistics
nixconfig-history stats
```

### Query Examples

**Find all changes to crisuflix:**
```bash
nixconfig-history host crisuflix
```

**Find all secrets-related changes:**
```bash
nixconfig-history category secrets
```

**Find recent documentation updates:**
```bash
nixconfig-history docs
```

**Search for when a service was added:**
```bash
nixconfig-history search "authelia"
```

## Host Detection

The system automatically detects affected hosts from file paths:

| File Pattern | Detected Host(s) |
|--------------|------------------|
| `hosts/laptop/*` | laptop |
| `hosts/vps/*` | vps |
| `hosts/crisuflix/*` | crisuflix |
| `hosts/rpi5/*` | rpi5 |
| `modules/core/*` | all-hosts |
| `flake.nix` | all-hosts |
| `secrets.nix` | all-hosts |
| `README.md`, `AGENTS.md` | docs |

## Change Categories

Automatically detected from commit messages:

| Pattern | Category |
|---------|----------|
| `add`, `feat` | add |
| `remove`, `delete`, `cleanup` | remove |
| `fix`, `bugfix` | fix |
| `update`, `bump`, `upgrade` | update |
| `move`, `migrate` | move |
| `refactor`, `rewrite` | refactor |
| `docs`, `readme` | docs |
| `agenix`, `secret` | secrets |

## Local Logs

As a fallback, changes are also logged locally to `.nixconfig-changes/YYYY-MM.log`:

```
---
DATE: 2026-04-03
COMMIT: 551dd38
HOSTS: crisuflix
CATEGORY: add
MESSAGE: add home-assistant integration
```

These logs are not committed to git (see `.gitignore`).
