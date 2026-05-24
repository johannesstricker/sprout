# Sprout - Git Worktree Management Utility

Sprout is a bash utility that simplifies git worktree management. It provides a convenient interface for creating, managing, and opening git worktrees with support for initialization hooks.

## Features

- **Simple worktree creation** - Create new worktrees with a single command
- **Configuration management** - Global configuration for worktree directory and editor preferences
- **Initialization hooks** - Run custom setup scripts when creating worktrees (e.g., copy `.env` files, install dependencies)
- **Editor integration** - Open worktrees with your preferred editor
- **Easy cleanup** - Remove worktrees with a simple command
- **Shell completions** - Tab completion for zsh, bash, and fish

## Installation

### Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/sprout.git
cd sprout

# Add bin directory to your PATH
export PATH="$PWD/bin:$PATH"

# Or create a symlink in a directory already in your PATH
ln -s "$(pwd)/bin/sprout" /usr/local/bin/sprout
```

### Configuration

Sprout stores its configuration in `~/.sproutrc`. You can modify it manually or use the `sprout config` command:

```bash
# Set the base directory for all worktrees
sprout config set worktree_dir ~/worktrees

# Set the default editor
sprout config set editor vim

# View current configuration
sprout config show
```

**Available configuration options:**
- `worktree_dir` - Base directory for all worktrees (default: `~/.sprout`)
- `editor` - Editor to use with `sprout open` and `sprout start` commands (default: `code`)

## Usage

### Creating a Worktree

```bash
# Create a worktree named 'feature-x' from the default branch (main)
sprout add feature-x

# Create a worktree from a specific branch
sprout add feature-x -b develop

# Create a worktree from a remote branch
sprout add feature-x -b origin/develop
```

The worktree will be created at `$worktree_dir/$repo_name/feature-x`

### Getting the Worktree Path

```bash
# Print the directory of a worktree
sprout dir feature-x

# Exit silently if the worktree doesn't exist (useful for scripts)
sprout dir nonexistent
```

### Creating and Opening a Worktree

```bash
# Create a worktree and immediately open it in the editor
sprout start feature-x

# Create from a specific branch and open with a specific editor
sprout start feature-x -b develop -e vim
```

### Opening a Worktree

```bash
# Open a worktree with the configured editor
sprout open feature-x

# Open a worktree with a specific editor
sprout open feature-x -e vim
```

### Removing a Worktree

```bash
# Remove a worktree
sprout rm feature-x

# Force removal (useful if there are uncommitted changes)
sprout rm feature-x -f
```

## Initialization Hooks

Sprout supports initialization hooks that run automatically when creating a worktree. This is useful for:
- Copying `.env` files from the main repository
- Installing dependencies
- Running setup scripts

There are two supported forms:

1. **`.sprout/init.yaml`** (preferred) — a declarative YAML file describing files to copy and commands to run. Requires `yq` and `jq` on `PATH`.
2. **`.sprout/init`** (fallback) — an executable shell script. Used only when no `init.yaml` is present.

### YAML hook format

```yaml
# .sprout/init.yaml

copy:
  # shorthand: copies <repo>/.env to <worktree>/.env
  - .env

  # explicit form with all options
  - src: config/secrets.json
    dest: config/secrets.json   # default: same path as src
    optional: true              # default: false (missing src is a hard error)
    name: "Project secrets"     # optional log label

  # globs in src work; each match keeps its filename
  - src: "config/*.local.json"
    optional: true

run:
  # shorthand
  - npm ci

  # explicit form
  - cmd: npm run prepare
    allow_failure: true         # default: false
    name: "Setup husky hooks"
```

**Semantics:**

- `copy:` runs before `run:`. Within each section, entries execute top-to-bottom.
- `copy.src` is resolved relative to the source repository root; `copy.dest` (and shorthand strings) are resolved relative to the new worktree.
- When `src` contains a glob and `dest` is set, `dest` is treated as a directory and each match is placed inside it.
- `optional: true` silently skips entries whose source does not exist (including empty glob expansions). Default is a hard error.
- `run.cmd` runs in the worktree with `$SPROUT_REPO_ROOT`, `$SPROUT_WORKTREE_PATH`, and `$SPROUT_WORKTREE_NAME` exported. A non-zero exit aborts unless `allow_failure: true`.
- Each step auto-logs a one-line summary; `name:` overrides the default text.

See `examples/init-node.yaml` and `examples/init-python.yaml` for working examples.

### Legacy shell hook

If `.sprout/init.yaml` is not present but an executable `.sprout/init` exists, sprout runs it as a bash script. The script executes in the worktree directory with the same three environment variables exported (`SPROUT_WORKTREE_PATH`, `SPROUT_REPO_ROOT`, `SPROUT_WORKTREE_NAME`). Use this when you need shell features the YAML form doesn't cover.

## Directory Structure

Worktrees are organized by repository:

```
~/.sprout/
├── my-project/
│   ├── feature-1/
│   ├── feature-2/
│   └── bugfix-3/
└── another-project/
    └── development/
```

You can change the base directory with:
```bash
sprout config set worktree_dir /path/to/worktrees
```

## Examples

### Typical Workflow

```bash
# Navigate to your repository
cd ~/projects/my-app

# Create a new worktree and open it in your editor
sprout start feature-dark-mode

# Or, if you prefer separate steps:
sprout add feature-dark-mode
sprout open feature-dark-mode

# Get the path for scripting
WORKTREE=$(sprout dir feature-dark-mode)
cd $WORKTREE

# Do your work...

# When done, remove the worktree
sprout rm feature-dark-mode
```

### Advanced: Automatic Setup with Hooks

Create `.sprout/init.yaml` in your repository:

```yaml
copy:
  - src: .env.template
    dest: .env

run:
  - npm ci
  - npm run build
```

Now every worktree will automatically have these set up!

## Shell Completions

Shell completions for **zsh**, **bash**, and **fish** are installed automatically with `make install`. They cover commands, worktree names, flags, config keys, and git branches.

You may need to restart your shell after installation. For zsh, you can also run:

```bash
autoload -Uz compinit && compinit
```

### Manual Setup (without Makefile)

**Zsh** - copy `completions/_sprout` to a directory in your `$fpath`:

```bash
mkdir -p ~/.zsh/completions
cp completions/_sprout ~/.zsh/completions/
# Add to ~/.zshrc:
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

**Bash** - source the completion script:

```bash
# Add to ~/.bashrc:
source /path/to/sprout/completions/sprout.bash
```

**Fish** - copy to fish completions directory:

```bash
cp completions/sprout.fish ~/.config/fish/completions/
```

## Troubleshooting

### "Not in a git repository" error

Make sure you're running sprout commands from within a git repository.

### "Branch not found" error

Ensure the branch exists locally or on the remote. Try:
```bash
git fetch origin  # Update remote tracking branches
sprout add my-feature -b origin/develop
```

### Init hook not running

- Check that `.sprout/init.yaml` (or the legacy `.sprout/init`) is in the repository root
- For YAML hooks, make sure `yq` and `jq` are installed and on `PATH`
- For shell hooks, sprout makes the file executable automatically
- Check the hook's output for errors
- The working directory is the new worktree, not the original repository

### Editor not found

If you see "Editor 'code' not found", either:
1. Install the editor you want to use
2. Change the default editor: `sprout config set editor vim`

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - feel free to use and modify as needed.
