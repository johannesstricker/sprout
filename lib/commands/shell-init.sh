#!/bin/bash
# sprout shell-init command - Print the shell integration for 'sprout cd'

# The wrapper intercepts 'sprout cd' and performs the directory change in the
# calling shell itself, using the path printed by 'sprout cd'. Every other
# subcommand is handed to the real binary untouched.
_shell_init_posix() {
    cat << 'EOF'
sprout() {
    if [ "$1" = "cd" ]; then
        shift
        local __sprout_dir
        __sprout_dir=$(command sprout cd "$@") || return $?
        cd "$__sprout_dir" || return $?
    else
        command sprout "$@"
    fi
}
EOF
}

_shell_init_fish() {
    cat << 'EOF'
function sprout
    if test (count $argv) -ge 1; and test "$argv[1]" = cd
        set -e argv[1]
        set -l __sprout_dir (command sprout cd $argv)
        or return 1
        test -n "$__sprout_dir"
        or return 1
        cd $__sprout_dir
    else
        command sprout $argv
    end
end
EOF
}

cmd_shell_init() {
    local shell="${1:-}"

    if [[ $# -gt 1 ]]; then
        echo "Error: Unexpected argument '$2'" >&2
        return 1
    fi

    # Fall back to the shell the user is running
    if [[ -z "$shell" ]]; then
        shell=$(basename "${SHELL:-}")
    fi

    case "$shell" in
        bash|zsh)
            _shell_init_posix
            ;;
        fish)
            _shell_init_fish
            ;;
        "")
            echo "Error: could not detect your shell, pass it explicitly" >&2
            echo "Usage: sprout shell-init <bash|zsh|fish>" >&2
            return 1
            ;;
        *)
            echo "Error: Unsupported shell '$shell'" >&2
            echo "Supported shells: bash, zsh, fish" >&2
            return 1
            ;;
    esac
}
