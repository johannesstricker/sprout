#!/bin/bash
# sprout list command - List all worktrees

cmd_list() {
    local worktrees_dir
    local verbose=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|--full|-v)
                verbose=true
                shift
                ;;
            *)
                echo "Error: Unknown option '$1'" >&2
                echo "Usage: sprout list [--verbose|--full|-v]" >&2
                return 1
                ;;
        esac
    done

    worktrees_dir=$(get_repo_worktrees_dir) || return 1

    # Check if worktrees directory exists
    if [[ ! -d "$worktrees_dir" ]]; then
        # No worktrees exist yet, exit silently
        return 0
    fi

    # Collect valid worktrees into an array using git worktree list
    local -a worktrees=()

    # Use git worktree list to get all worktrees, then filter for our managed directory
    while IFS= read -r line; do
        if [[ "$line" =~ ^worktree\ (.+)$ ]]; then
            local worktree_path="${BASH_REMATCH[1]}"
            # Only include worktrees in our managed directory
            if [[ "$worktree_path" == "$worktrees_dir"/* ]]; then
                if [[ "$verbose" == true ]]; then
                    worktrees+=("$worktree_path")
                else
                    # Extract relative path from worktrees_dir
                    local relative_path="${worktree_path#"$worktrees_dir/"}"
                    worktrees+=("$relative_path")
                fi
            fi
        fi
    done < <(git worktree list --porcelain)

    # Sort and print worktrees
    if [[ ${#worktrees[@]} -gt 0 ]]; then
        printf '%s\n' "${worktrees[@]}" | sort
    fi
}
