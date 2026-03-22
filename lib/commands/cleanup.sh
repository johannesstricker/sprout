#!/bin/bash
# sprout cleanup command - Remove worktrees whose branches have been merged to main

cmd_cleanup() {
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -*)
                echo "Error: Unknown option '$1'" >&2
                echo "Usage: sprout cleanup [-n|--dry-run]" >&2
                return 1
                ;;
            *)
                echo "Error: Unexpected argument '$1'" >&2
                echo "Usage: sprout cleanup [-n|--dry-run]" >&2
                return 1
                ;;
        esac
    done

    local worktrees_dir
    worktrees_dir=$(get_repo_worktrees_dir) || return 1

    # Check if worktrees directory exists
    if [[ ! -d "$worktrees_dir" ]]; then
        echo "No worktrees to clean up"
        return 0
    fi

    local default_branch
    default_branch=$(get_default_branch)

    # Collect managed worktrees
    local -a to_remove=()

    while IFS= read -r line; do
        if [[ "$line" =~ ^worktree\ (.+)$ ]]; then
            local worktree_path="${BASH_REMATCH[1]}"
            if [[ "$worktree_path" == "$worktrees_dir"/* ]]; then
                # Get the branch checked out in this worktree
                local branch
                branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null) || continue

                # Check if the branch has been merged into the default branch
                if git merge-base --is-ancestor "$branch" "$default_branch" 2>/dev/null; then
                    local name="${worktree_path#"$worktrees_dir/"}"
                    to_remove+=("$name")
                fi
            fi
        fi
    done < <(git worktree list --porcelain)

    if [[ ${#to_remove[@]} -eq 0 ]]; then
        echo "No merged worktrees to clean up"
        return 0
    fi

    if [[ "$dry_run" == true ]]; then
        echo "Would remove the following worktrees:"
        for name in "${to_remove[@]}"; do
            echo "  $name"
        done
        return 0
    fi

    for name in "${to_remove[@]}"; do
        local worktree_path="${worktrees_dir}/${name}"
        local branch
        branch=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null) || true

        echo "Removing worktree '$name'..."
        if git worktree remove --force "$worktree_path" 2>/dev/null; then
            # Delete the branch if it still exists
            if [[ -n "$branch" ]] && [[ "$branch" != "$default_branch" ]]; then
                if git rev-parse --verify "$branch" > /dev/null 2>&1; then
                    git branch -d "$branch" 2>/dev/null || true
                fi
            fi
            echo "  Removed worktree and branch '$branch'"
        else
            echo "  Warning: Failed to remove worktree '$name'" >&2
        fi
    done

    # Clean up empty parent directory
    if [[ -d "$worktrees_dir" ]] && [[ -z "$(ls -A "$worktrees_dir" 2>/dev/null)" ]]; then
        rmdir "$worktrees_dir" 2>/dev/null || true
    fi

    echo "Cleanup complete: removed ${#to_remove[@]} worktree(s)"
}
