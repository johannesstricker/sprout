#!/bin/bash
# sprout cleanup command - Remove worktrees whose branches have been merged to the default branch

cmd_cleanup() {
    local dry_run=false
    local worktrees_dir
    local default_branch
    local current_path=""
    local current_branch=""
    local -a to_remove=()
    local -a to_remove_branches=()
    local removed_count=0
    local i
    local name
    local branch
    local worktree_path
    local remove_error

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

    worktrees_dir=$(get_repo_worktrees_dir) || return 1

    # Check if worktrees directory exists
    if [[ ! -d "$worktrees_dir" ]]; then
        echo "No worktrees to clean up"
        return 0
    fi

    default_branch=$(get_default_branch) || return 1

    # Collect managed worktrees whose branches have been merged into the default branch.
    # Parse git worktree list --porcelain to get both path and branch in a single pass,
    # avoiding a separate git subprocess per worktree.
    while IFS= read -r line; do
        if [[ "$line" =~ ^worktree\ (.+)$ ]]; then
            current_path="${BASH_REMATCH[1]}"
            current_branch=""
        elif [[ "$line" =~ ^branch\ refs/heads/(.+)$ ]]; then
            current_branch="${BASH_REMATCH[1]}"
        elif [[ "$line" == "detached" ]]; then
            current_branch="HEAD"
        elif [[ -z "$line" ]] && [[ -n "$current_path" ]]; then
            # End of a worktree block — check if it should be removed.
            # Skip: worktrees outside the managed dir, detached HEAD, or on the default branch itself.
            if [[ "$current_path" == "$worktrees_dir"/* ]] && \
               [[ -n "$current_branch" ]] && \
               [[ "$current_branch" != "HEAD" ]] && \
               [[ "$current_branch" != "$default_branch" ]]; then
                if git merge-base --is-ancestor "$current_branch" "$default_branch" 2>/dev/null; then
                    to_remove+=("${current_path#"$worktrees_dir/"}")
                    to_remove_branches+=("$current_branch")
                fi
            fi
            current_path=""
            current_branch=""
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

    for i in "${!to_remove[@]}"; do
        name="${to_remove[$i]}"
        branch="${to_remove_branches[$i]}"
        worktree_path="${worktrees_dir}/${name}"

        echo "Removing worktree '$name'..."
        if remove_error=$(git worktree remove "$worktree_path" 2>&1); then
            # Delete the branch if it still exists
            if [[ -n "$branch" ]] && [[ "$branch" != "$default_branch" ]]; then
                if git rev-parse --verify "$branch" > /dev/null 2>&1; then
                    git branch -d "$branch" 2>/dev/null || true
                fi
            fi
            echo "  Removed worktree and branch '$branch'"
            ((removed_count++))
        else
            echo "  Skipping '$name': $remove_error (use 'sprout rm -f $name' to force)" >&2
        fi
    done

    # Clean up empty parent directory
    if [[ -d "$worktrees_dir" ]] && [[ -z "$(ls -A "$worktrees_dir" 2>/dev/null)" ]]; then
        rmdir "$worktrees_dir" 2>/dev/null || true
    fi

    echo "Cleanup complete: removed ${removed_count} worktree(s)"
}
