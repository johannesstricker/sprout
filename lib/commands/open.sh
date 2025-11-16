#!/bin/bash
# sprout open command - Open a worktree with the configured editor

cmd_open() {
    local name=""
    local editor=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
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
        echo "Usage: sprout open <name> [-e <editor>]" >&2
        return 1
    fi

    # Check if worktree exists
    local worktree_path
    worktree_path=$(get_worktree_path "$name") || return 1

    if [[ ! -d "$worktree_path" ]]; then
        echo "Error: Worktree '$name' does not exist" >&2
        return 1
    fi

    # Get editor from config if not specified
    if [[ -z "$editor" ]]; then
        editor=$(get_editor)
    fi

    # Open the worktree with the editor
    echo "Opening worktree '$name' with '$editor'..."

    # Execute the editor in the background and detach from terminal
    if command -v "$editor" > /dev/null 2>&1; then
        "$editor" "$worktree_path" &
        disown 2>/dev/null || true
    else
        echo "Error: Editor '$editor' not found" >&2
        echo "Please install '$editor' or configure a different editor with: sprout config set editor <name>" >&2
        return 1
    fi

    return 0
}
