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

    # Resolve the expected worktree path
    local worktree_path
    worktree_path=$(get_worktree_path "$name") || return 1

    local dir_exists=false
    [[ -d "$worktree_path" ]] && dir_exists=true

    # Check if git still has this worktree registered, even if the directory
    # has been deleted out from under it (orphaned registration).
    local registered=false
    if git worktree list --porcelain 2>/dev/null | grep -qxF "worktree $worktree_path"; then
        registered=true
    fi

    if [[ "$dir_exists" == false && "$registered" == false ]]; then
        echo "Error: Worktree '$name' does not exist" >&2
        return 1
    fi

    echo "Removing worktree '$name'..."

    if [[ "$dir_exists" == true && "$registered" == true ]]; then
        # Normal case: directory exists and git knows about it
        local remove_output
        if [[ "$force" == true ]]; then
            if ! remove_output=$(git worktree remove --force "$worktree_path" 2>&1); then
                echo "Error: Failed to remove git worktree (with --force): $remove_output" >&2
                return 1
            fi
        else
            if ! remove_output=$(git worktree remove "$worktree_path" 2>&1); then
                echo "Error: Failed to remove git worktree: $remove_output" >&2
                echo "Use -f flag to force removal" >&2
                return 1
            fi
        fi
    elif [[ "$registered" == true ]]; then
        # Orphaned registration: directory was deleted but git still tracks it.
        # git worktree remove handles missing directories (git 2.17+), targeting
        # only this worktree rather than pruning all stale registrations globally.
        echo "Worktree directory missing; removing orphaned registration..."
        local remove_output
        if ! remove_output=$(git worktree remove "$worktree_path" 2>&1); then
            echo "Error: Failed to remove git worktree registration: $remove_output" >&2
            return 1
        fi
    else
        # Orphaned directory: not registered with git
        echo "Warning: Worktree not registered with git, removing directory anyway..."
    fi

    # Safety net: remove any leftover directory in case git worktree remove did
    # not fully clean up, or for directories that were never registered with git.
    if [[ -d "$worktree_path" ]]; then
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
