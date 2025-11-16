#!/bin/bash
# Hook management for sprout

# Path to the init hook in a repository
HOOK_PATH=".sprout/init"

# Check if an init hook exists in the repository
has_init_hook() {
    local repo_root
    repo_root=$(get_repo_root) || return 1

    if [[ -f "${repo_root}/${HOOK_PATH}" ]]; then
        return 0
    else
        return 1
    fi
}

# Execute the init hook if it exists
run_init_hook() {
    local worktree_path="$1"

    if ! has_init_hook; then
        return 0
    fi

    local repo_root
    local hook_file
    repo_root=$(get_repo_root) || return 1
    hook_file="${repo_root}/${HOOK_PATH}"

    # Make hook executable
    chmod +x "$hook_file"

    # Create a subshell environment with necessary variables
    (
        # Set environment variables that the hook might need
        export SPROUT_WORKTREE_PATH="$worktree_path"
        export SPROUT_REPO_ROOT="$repo_root"
        export SPROUT_WORKTREE_NAME="$(basename "$worktree_path")"

        # Change to the worktree directory for the hook execution
        cd "$worktree_path"

        # Execute the hook
        if ! bash "$hook_file"; then
            echo "Error: Init hook failed" >&2
            return 1
        fi
    ) || return 1

    return 0
}
