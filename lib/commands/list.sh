#!/bin/bash
# sprout list command - List all worktrees

cmd_list() {
    local worktrees_dir
    worktrees_dir=$(get_repo_worktrees_dir) || return 1

    # Check if worktrees directory exists
    if [[ ! -d "$worktrees_dir" ]]; then
        # No worktrees exist yet, exit silently
        return 0
    fi

    # List all directories in the worktrees directory
    # Each directory represents a worktree
    for dir in "$worktrees_dir"/*; do
        if [[ -d "$dir" ]]; then
            basename "$dir"
        fi
    done
}
