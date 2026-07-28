#!/bin/bash
# sprout cd command - Change into the directory of a worktree

cmd_cd() {
    local name=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
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
        echo "Usage: sprout cd <name>" >&2
        return 1
    fi

    # Check if worktree exists
    local worktree_path
    worktree_path=$(get_worktree_path "$name") || return 1

    if [[ ! -d "$worktree_path" ]]; then
        echo "Error: Worktree '$name' does not exist" >&2
        return 1
    fi

    cd "$worktree_path" || return 1

    # A child process cannot change the working directory of its parent, so
    # start a new shell in the worktree instead. Leave it with 'exit' to
    # return to where you were. Shell integration (see README) overrides this
    # command to change the directory of the current shell.
    local shell="${SHELL:-/bin/bash}"

    if ! command -v "$shell" > /dev/null 2>&1; then
        echo "Error: Shell '$shell' not found" >&2
        return 1
    fi

    exec "$shell"
}
