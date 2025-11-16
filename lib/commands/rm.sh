#!/bin/bash
# sprout rm command - Remove a worktree

cmd_rm() {
    local name=""
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--force)
                force=true
                shift
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
        echo "Usage: sprout rm <name> [-f]" >&2
        return 1
    fi

    # Check if worktree exists
    local worktree_path
    worktree_path=$(get_worktree_path "$name") || return 1

    if [[ ! -d "$worktree_path" ]]; then
        echo "Error: Worktree '$name' does not exist" >&2
        return 1
    fi

    # Check if it's a git worktree
    if is_git_worktree "$worktree_path"; then
        echo "Removing worktree '$name'..."

        # Remove the git worktree
        if [[ "$force" == true ]]; then
            if ! git worktree remove --force "$worktree_path"; then
                echo "Error: Failed to remove git worktree (with --force)" >&2
                return 1
            fi
        else
            if ! git worktree remove "$worktree_path"; then
                echo "Error: Failed to remove git worktree" >&2
                echo "Use -f flag to force removal" >&2
                return 1
            fi
        fi
    else
        # If it's not registered as a git worktree, just remove the directory
        echo "Warning: Worktree not registered with git, removing directory anyway..."
        rm -rf "$worktree_path"
    fi

    echo "Worktree '$name' removed successfully"

    # Clean up empty parent directory if it exists
    local worktrees_dir
    worktrees_dir=$(get_repo_worktrees_dir) || true
    if [[ -d "$worktrees_dir" ]] && [[ -z "$(ls -A "$worktrees_dir" 2>/dev/null)" ]]; then
        rmdir "$worktrees_dir" 2>/dev/null || true
    fi

    return 0
}
