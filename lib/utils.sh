#!/bin/bash
# Utility functions for sprout

# Get the name of the current git repository
get_repo_name() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    local repo_dir
    repo_dir=$(git rev-parse --show-toplevel)
    basename "$repo_dir"
}

# Get the top-level directory of the current git repository
get_repo_root() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository" >&2
        return 1
    fi

    git rev-parse --show-toplevel
}

# Get the worktree base directory for the current repository
get_repo_worktrees_dir() {
    local repo_name
    local worktree_base_dir

    repo_name=$(get_repo_name) || return 1
    worktree_base_dir=$(get_worktree_dir)

    echo "${worktree_base_dir}/${repo_name}"
}

# Get the full path to a specific worktree
get_worktree_path() {
    local name="$1"
    local worktrees_dir

    worktrees_dir=$(get_repo_worktrees_dir) || return 1
    echo "${worktrees_dir}/${name}"
}

# Check if a worktree exists
worktree_exists() {
    local name="$1"
    local path

    path=$(get_worktree_path "$name") || return 1

    if [[ -d "$path" ]]; then
        return 0
    else
        return 1
    fi
}

# Get the default branch for the repository
get_default_branch() {
    # Try to get the remote default branch
    local default_branch
    default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|^refs/remotes/origin/||' || echo "main")
    echo "$default_branch"
}

# Validate branch name
validate_branch() {
    local branch="$1"

    # Check if branch exists locally or on remote
    if git rev-parse --verify "$branch" > /dev/null 2>&1; then
        return 0
    fi

    if git rev-parse --verify "origin/$branch" > /dev/null 2>&1; then
        return 0
    fi

    echo "Error: Branch '$branch' not found" >&2
    return 1
}
