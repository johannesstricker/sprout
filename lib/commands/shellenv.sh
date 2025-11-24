#!/bin/bash
# sprout shellenv command - Output shell completion scripts

# Detect the current shell
detect_shell() {
    local shell_path="${SHELL:-}"

    if [[ -n "$shell_path" ]]; then
        # Extract shell name from path
        local shell_name
        shell_name=$(basename "$shell_path")

        case "$shell_name" in
            bash)
                echo "bash"
                ;;
            zsh)
                echo "zsh"
                ;;
            fish)
                echo "fish"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# Generate bash completions
generate_bash_completions() {
    cat << 'BASH_COMPLETION'
# Bash completion for sprout
_sprout_completions() {
    local cur prev words cword
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Main commands
    local commands="add dir list rm open config shellenv help"

    case "$prev" in
        sprout)
            COMPREPLY=($(compgen -W "$commands" -- "$cur"))
            ;;
        open|dir|rm)
            # Complete with existing worktree names
            local worktrees
            worktrees=$(sprout list 2>/dev/null)
            COMPREPLY=($(compgen -W "$worktrees" -- "$cur"))
            ;;
        add)
            # After add, expect a name or -b flag
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "-b" -- "$cur"))
            fi
            ;;
        -b)
            # Complete with branch names
            local branches
            branches=$(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)
            COMPREPLY=($(compgen -W "$branches" -- "$cur"))
            ;;
        config)
            COMPREPLY=($(compgen -W "set get show" -- "$cur"))
            ;;
        set|get)
            COMPREPLY=($(compgen -W "worktree_dir editor" -- "$cur"))
            ;;
        shellenv)
            COMPREPLY=($(compgen -W "bash zsh fish" -- "$cur"))
            ;;
        list)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--verbose --full -v" -- "$cur"))
            fi
            ;;
    esac

    return 0
}
complete -F _sprout_completions sprout
BASH_COMPLETION
}

# Generate zsh completions
generate_zsh_completions() {
    cat << 'ZSH_COMPLETION'
# Zsh completion for sprout
#compdef sprout

_sprout() {
    local -a commands
    commands=(
        'add:Create a new worktree'
        'dir:Print the directory path of a worktree'
        'list:List all worktrees'
        'rm:Remove a worktree'
        'open:Open a worktree with editor'
        'config:Manage configuration'
        'shellenv:Output shell completions'
        'help:Show help message'
    )

    local -a config_subcommands
    config_subcommands=(
        'set:Set a configuration value'
        'get:Get a configuration value'
        'show:Show all configuration'
    )

    local -a config_keys
    config_keys=(
        'worktree_dir:Base directory for worktrees'
        'editor:Editor to use with open command'
    )

    _arguments -C \
        '1: :->command' \
        '*: :->args'

    case $state in
        command)
            _describe 'command' commands
            ;;
        args)
            case $words[2] in
                open|dir|rm)
                    # Complete with worktree names
                    local -a worktrees
                    worktrees=(${(f)"$(sprout list 2>/dev/null)"})
                    _describe 'worktree' worktrees
                    ;;
                add)
                    _arguments \
                        '-b[Branch to checkout]:branch:_git_branch_names' \
                        '1:worktree name:'
                    ;;
                config)
                    if (( CURRENT == 3 )); then
                        _describe 'config subcommand' config_subcommands
                    elif (( CURRENT == 4 )); then
                        case $words[3] in
                            set|get)
                                _describe 'config key' config_keys
                                ;;
                        esac
                    fi
                    ;;
                shellenv)
                    local -a shells
                    shells=('bash' 'zsh' 'fish')
                    _describe 'shell' shells
                    ;;
                list)
                    _arguments \
                        '(-v --verbose --full)'{-v,--verbose,--full}'[Show full paths]'
                    ;;
            esac
            ;;
    esac
}

# Helper function for git branch names if not already defined
if ! type _git_branch_names &>/dev/null; then
    _git_branch_names() {
        local -a branches
        branches=(${(f)"$(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)"})
        _describe 'branch' branches
    }
fi

_sprout "$@"
ZSH_COMPLETION
}

# Generate fish completions
generate_fish_completions() {
    cat << 'FISH_COMPLETION'
# Fish completion for sprout

# Disable file completions for sprout
complete -c sprout -f

# Main commands
complete -c sprout -n "__fish_use_subcommand" -a "add" -d "Create a new worktree"
complete -c sprout -n "__fish_use_subcommand" -a "dir" -d "Print worktree directory"
complete -c sprout -n "__fish_use_subcommand" -a "list" -d "List all worktrees"
complete -c sprout -n "__fish_use_subcommand" -a "rm" -d "Remove a worktree"
complete -c sprout -n "__fish_use_subcommand" -a "open" -d "Open worktree in editor"
complete -c sprout -n "__fish_use_subcommand" -a "config" -d "Manage configuration"
complete -c sprout -n "__fish_use_subcommand" -a "shellenv" -d "Output shell completions"
complete -c sprout -n "__fish_use_subcommand" -a "help" -d "Show help"

# Complete worktree names for open/dir/rm
complete -c sprout -n "__fish_seen_subcommand_from open dir rm" -a "(sprout list 2>/dev/null)"

# Options for add command
complete -c sprout -n "__fish_seen_subcommand_from add" -s b -d "Branch to checkout" -xa "(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)"

# Options for list command
complete -c sprout -n "__fish_seen_subcommand_from list" -s v -l verbose -d "Show full paths"
complete -c sprout -n "__fish_seen_subcommand_from list" -l full -d "Show full paths"

# Options for rm command
complete -c sprout -n "__fish_seen_subcommand_from rm" -s f -d "Force removal"

# Config subcommands
complete -c sprout -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from set get show" -a "set" -d "Set a configuration value"
complete -c sprout -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from set get show" -a "get" -d "Get a configuration value"
complete -c sprout -n "__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from set get show" -a "show" -d "Show all configuration"

# Config keys for set/get
complete -c sprout -n "__fish_seen_subcommand_from set get" -a "worktree_dir" -d "Base directory for worktrees"
complete -c sprout -n "__fish_seen_subcommand_from set get" -a "editor" -d "Editor to use with open command"

# Shell types for shellenv
complete -c sprout -n "__fish_seen_subcommand_from shellenv" -a "bash zsh fish"
FISH_COMPLETION
}

# Main shellenv command
cmd_shellenv() {
    local shell="${1:-}"

    # Auto-detect shell if not specified
    if [[ -z "$shell" ]]; then
        shell=$(detect_shell)
    fi

    case "$shell" in
        bash)
            generate_bash_completions
            ;;
        zsh)
            generate_zsh_completions
            ;;
        fish)
            generate_fish_completions
            ;;
        unknown)
            echo "Error: Could not detect shell. Please specify: sprout shellenv <bash|zsh|fish>" >&2
            return 1
            ;;
        *)
            echo "Error: Unknown shell '$shell'. Supported shells: bash, zsh, fish" >&2
            return 1
            ;;
    esac
}
