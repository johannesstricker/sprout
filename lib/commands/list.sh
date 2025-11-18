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

    # Collect valid worktrees into an array
    local -a worktrees=()

    for dir in "$worktrees_dir"/*; do
        if [[ -d "$dir" ]] && is_git_worktree "$dir"; then
            if [[ "$verbose" == true ]]; then
                worktrees+=("$dir")
            else
                worktrees+=("$(basename "$dir")")
            fi
        fi
    done

    # Sort and print worktrees
    if [[ ${#worktrees[@]} -gt 0 ]]; then
        printf '%s\n' "${worktrees[@]}" | sort
    fi
}
