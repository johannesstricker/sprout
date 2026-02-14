#!/bin/bash
# sprout start command - Create a new worktree and open it in the editor

cmd_start() {
    local name=""
    local branch=""
    local branch_specified=false
    local editor=""
    local add_args=()
    local open_args=()

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
    add_args=("$name")
    if [[ "$branch_specified" == true ]]; then
        add_args+=("-b" "$branch")
    fi

    # Create the worktree
    if ! cmd_add "${add_args[@]}"; then
        return 1
    fi

    # Build args for open command
    open_args=("$name")
    if [[ -n "$editor" ]]; then
        open_args+=("-e" "$editor")
    fi

    # Open the worktree
    cmd_open "${open_args[@]}"
}
