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

    # A process cannot change the working directory of the shell that started
    # it, so the actual 'cd' is done by the shell function from
    # 'sprout shell-init', which captures the path printed below.
    #
    # A terminal on stdout therefore means that wrapper is not installed:
    # printing a path would look like the command silently did nothing, so
    # explain how to set it up instead.
    if [[ -t 1 ]]; then
        cat >&2 << 'EOF'
Error: 'sprout cd' needs shell integration to change your current directory.

Add one of these to your shell config, then restart your shell:

  bash    eval "$(sprout shell-init bash)"       # ~/.bashrc
  zsh     eval "$(sprout shell-init zsh)"        # ~/.zshrc
  fish    sprout shell-init fish | source        # ~/.config/fish/config.fish

Until then, use: cd "$(sprout dir <name>)"
EOF
        return 1
    fi

    echo "$worktree_path"
}
