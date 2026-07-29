#!/bin/bash
# sprout dir command - Print the directory of a worktree

cmd_dir() {
    local name="${1:-}"

    if [[ -z "$name" ]]; then
        echo "Error: worktree name is required" >&2
        echo "Usage: sprout dir <name>" >&2
        return 1
    fi

    local worktree_path
    worktree_path=$(get_worktree_path "$name") || return 1

    if worktree_exists "$name"; then
        echo "$worktree_path"
        return 0
    else
        # Exit silently with no output if worktree doesn't exist
        return 0
    fi
}
