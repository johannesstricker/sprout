#!/bin/bash
# sprout checkout command - Checkout an existing branch into a new worktree

cmd_checkout() {
    local branch=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -*)
                echo "Error: Unknown option '$1'" >&2
                return 1
                ;;
            *)
                if [[ -z "$branch" ]]; then
                    branch="$1"
                    shift
                else
                    echo "Error: Unexpected argument '$1'" >&2
                    return 1
                fi
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$branch" ]]; then
        echo "Error: branch name is required" >&2
        echo "Usage: sprout checkout <branch>" >&2
        return 1
    fi

    # Derive worktree name by stripping origin/ prefix
    local name="$branch"
    name="${name#origin/}"

    # Verify the branch exists (locally, as explicit ref, or on remote)
    if ! git rev-parse --verify "$branch" > /dev/null 2>&1; then
        if ! git rev-parse --verify "origin/$name" > /dev/null 2>&1; then
            echo "Error: Branch '$branch' not found" >&2
            return 1
        fi
    fi

    # Get paths
    local worktrees_dir worktree_path
    worktrees_dir=$(get_repo_worktrees_dir) || return 1
    worktree_path="${worktrees_dir}/${name}"

    # Check if worktree already exists
    if [[ -d "$worktree_path" ]]; then
        echo "Error: Worktree '$name' already exists at $worktree_path" >&2
        return 1
    fi

    # Create worktrees directory if it doesn't exist
    if [[ ! -d "$worktrees_dir" ]]; then
        mkdir -p "$worktrees_dir"
    fi

    # Create the worktree (no -b flag: git DWIM creates tracking branch for remote-only)
    echo "Checking out branch '$name' into worktree '$name'..."
    if ! git worktree add "$worktree_path" "$name"; then
        echo "Error: Failed to create git worktree" >&2
        rm -rf "$worktree_path" 2>/dev/null || true
        return 1
    fi

    echo "Worktree created successfully at: $worktree_path"

    # Run init hook if it exists. Hook failures propagate so the user knows
    # their worktree is not fully set up.
    if ! run_init_hook "$worktree_path"; then
        echo "Error: Initialization hook failed" >&2
        return 1
    fi

    return 0
}
