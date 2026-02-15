#!/bin/bash
# sprout start command - Create a new worktree and open it in the editor

cmd_start() {
    local name=""
    local branch=""
    local editor=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -b)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: -b requires a branch name" >&2
                    return 1
                fi
                branch="$2"
                shift 2
                ;;
            -e|--editor)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: -e requires an editor name" >&2
                    return 1
                fi
                editor="$2"
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
        echo "Usage: sprout start <name> [-b <branch>] [-e <editor>]" >&2
        return 1
    fi

    # Build args for add command
    local add_args=("$name")
    if [[ -n "$branch" ]]; then
        add_args+=("-b" "$branch")
    fi

    # Create the worktree
    if ! cmd_add "${add_args[@]}"; then
        return 1
    fi

    # Build args for open command
    local open_args=("$name")
    if [[ -n "$editor" ]]; then
        open_args+=("-e" "$editor")
    fi

    # Open the worktree
    if ! cmd_open "${open_args[@]}"; then
        echo "Warning: Worktree created but failed to open. Use 'sprout open $name' to retry." >&2
        return 1
    fi
}
