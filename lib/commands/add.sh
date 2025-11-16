#!/bin/bash
# sprout add command - Create a new worktree

cmd_add() {
    local name=""
    local branch=""
    local branch_specified=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: -b requires a branch name" >&2
                    return 1
                fi
                branch="$2"
                branch_specified=true
                shift 2
                ;;
            -*)
                echo "Error: Unknown option '$1'" >&2
                return 1
                ;;
            *)
                if [[ -z "$name" ]]; then
                    name="$1"
                    shift
                else
                    echo "Error: Unexpected argument '$1'" >&2
                    return 1
                fi
                ;;
        esac
    done

    # Validate arguments
    if [[ -z "$name" ]]; then
        echo "Error: worktree name is required" >&2
        echo "Usage: sprout add <name> [-b <branch>]" >&2
        return 1
    fi

    # Use default branch if not specified
    if [[ "$branch_specified" == false ]]; then
        branch=$(get_default_branch)
    fi

    # Validate branch exists
    if ! validate_branch "$branch"; then
        return 1
    fi

    # Get paths
    local worktrees_dir repo_root worktree_path
    worktrees_dir=$(get_repo_worktrees_dir) || return 1
    repo_root=$(get_repo_root) || return 1
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

    # Create the worktree
    echo "Creating worktree '$name' from branch '$branch'..."
    if ! git worktree add -b "$name" "$worktree_path" "$branch"; then
        echo "Error: Failed to create git worktree" >&2
        # Attempt cleanup
        rm -rf "$worktree_path" 2>/dev/null || true
        return 1
    fi

    echo "Worktree created successfully at: $worktree_path"

    # Run init hook if it exists
    echo "Checking for initialization hook..."
    if run_init_hook "$worktree_path"; then
        echo "Initialization hook executed successfully"
    fi

    return 0
}
