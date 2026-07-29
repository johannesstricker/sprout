# Sprout - Git Worktree Management Utility

Sprout is a bash utility that simplifies git worktree management. It provides a convenient interface for creating, managing, and opening git worktrees with support for initialization hooks.

## Features

- **Simple worktree creation** - Create new worktrees with a single command
- **Configuration management** - Global configuration for worktree directory and editor preferences
- **Initialization hooks** - Run custom setup scripts when creating worktrees (e.g., copy `.env` files, install dependencies)
- **Editor integration** - Open worktrees with your preferred editor
- **Shell integration** - Jump into a worktree with `sprout cd` in zsh, bash, and fish
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

### Changing into a Worktree

```bash
# Change into the directory of a worktree
sprout cd feature-x
```

This requires shell integration (see below). A process can never change the
working directory of the shell that started it, so `sprout cd` needs a small
wrapper function in your shell - the same approach used by tools like `zoxide`
and `direnv`. Without it, `sprout cd` prints setup instructions instead of
silently doing nothing.

### Shell Integration

Add the matching line to your shell config and restart your shell:

```bash
# ~/.bashrc
eval "$(sprout shell-init bash)"

# ~/.zshrc
eval "$(sprout shell-init zsh)"
```

```fish
# ~/.config/fish/config.fish
sprout shell-init fish | source
```

`sprout shell-init` defaults to the shell in `$SHELL`, so a bare
`eval "$(sprout shell-init)"` works too. Run it without `eval` to see exactly
what it defines: a `sprout` function that handles `cd` itself and passes every
other subcommand through to the real binary, so the rest of sprout - including
tab completion - is unaffected.

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
- Creating necessary directories

### Creating an Init Hook

In your git repository, create a `.sprout/init` file with your setup script:

```bash
#!/bin/bash
# .sprout/init - Initialize sprout worktrees

set -e

echo "Setting up worktree..."

# Copy .env file from main repository
if [ -f "$SPROUT_REPO_ROOT/.env" ]; then
    cp "$SPROUT_REPO_ROOT/.env" .env
    echo "Copied .env file"
fi

# Copy .env.example and rename it
if [ -f "$SPROUT_REPO_ROOT/.env.example" ]; then
    cp "$SPROUT_REPO_ROOT/.env.example" .env.local
    echo "Copied .env.example"
fi

# Install dependencies (example for Node.js)
if [ -f "package.json" ]; then
    npm install
    echo "Dependencies installed"
fi

echo "Worktree initialized successfully!"
```

### Hook Environment Variables

The init hook has access to the following environment variables:

- `SPROUT_WORKTREE_PATH` - Full path to the created worktree
- `SPROUT_REPO_ROOT` - Path to the source repository root
- `SPROUT_WORKTREE_NAME` - Name of the worktree (last component of path)

The hook executes in the worktree directory (working directory is automatically changed).

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

# Jump into the worktree in your shell
sprout cd feature-dark-mode

# Or get the path for scripting
WORKTREE=$(sprout dir feature-dark-mode)
cd $WORKTREE

# Do your work...

# When done, remove the worktree
sprout rm feature-dark-mode
```

### Advanced: Automatic Setup with Hooks

Create `.sprout/init` in your repository:

```bash
#!/bin/bash
# Setup script for worktrees

# Copy configuration
cp "$SPROUT_REPO_ROOT/.env.template" .env

# Setup database
if command -v psql &> /dev/null; then
    psql -U postgres -c "CREATE DATABASE myapp_${SPROUT_WORKTREE_NAME};"
fi

# Install and build
npm install
npm run build
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

- Check that `.sprout/init` is in the repository root
- Make sure the file is executable (sprout will make it executable automatically)
- Check the init hook's output for errors
- The working directory is the new worktree, not the original repository

### Editor not found

If you see "Editor 'code' not found", either:
1. Install the editor you want to use
2. Change the default editor: `sprout config set editor vim`

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - feel free to use and modify as needed.
