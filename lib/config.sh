#!/bin/bash
# Configuration management for sprout

CONFIG_FILE="${HOME}/.sproutrc"
DEFAULT_WORKTREE_DIR="${HOME}/.sprout"
DEFAULT_EDITOR="code"

# Initialize config file if it doesn't exist
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" << EOF
# Sprout Configuration File
# This file stores your sprout settings

# Base directory for all worktrees
worktree_dir=$DEFAULT_WORKTREE_DIR

# Editor to use with 'sprout open' command
editor=$DEFAULT_EDITOR
EOF
        chmod 644 "$CONFIG_FILE"
    fi
}

# Get a configuration value
get_config() {
    local key="$1"
    local default="${2:-}"

    init_config

    # Try to get the value from config file
    local value
    value=$(grep "^${key}=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' || echo "")

    if [[ -z "$value" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Set a configuration value
set_config() {
    local key="$1"
    local value="$2"

    init_config

    # Check if key exists
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        # Update existing key
        sed -i.bak "s|^${key}=.*|${key}=${value}|" "$CONFIG_FILE"
        rm -f "${CONFIG_FILE}.bak"
    else
        # Add new key
        echo "${key}=${value}" >> "$CONFIG_FILE"
    fi
}

# Show all configuration
show_config() {
    init_config
    echo "Sprout Configuration:"
    echo "Configuration file: $CONFIG_FILE"
    echo ""
    grep -v "^#" "$CONFIG_FILE" | grep -v "^$" || true
}

# Validate and get worktree directory
get_worktree_dir() {
    local dir
    dir=$(get_config "worktree_dir" "$DEFAULT_WORKTREE_DIR")
    echo "$dir"
}

# Validate and get editor
get_editor() {
    local editor
    editor=$(get_config "editor" "$DEFAULT_EDITOR")
    echo "$editor"
}

# Handle config command
cmd_config() {
    local subcommand="${1:-}"

    case "$subcommand" in
        set)
            if [[ $# -lt 3 ]]; then
                echo "Error: config set requires a key and value" >&2
                return 1
            fi
            set_config "$2" "$3"
            echo "Configuration updated: $2=$3"
            ;;
        get)
            if [[ $# -lt 2 ]]; then
                echo "Error: config get requires a key" >&2
                return 1
            fi
            get_config "$2"
            ;;
        show)
            show_config
            ;;
        *)
            echo "Error: Unknown config subcommand '$subcommand'" >&2
            echo "Available subcommands: set, get, show" >&2
            return 1
            ;;
    esac
}
