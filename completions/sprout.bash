# Bash completion for sprout - Git worktree management utility

_sprout() {
    local cur prev words cword
    _init_completion || return

    local commands="add dir list rm open start config help"
    local config_subcmds="set get show"
    local config_keys="worktree_dir editor"

    # Complete commands at position 1
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
        return
    fi

    local cmd="${words[1]}"

    case "$cmd" in
        add)
            case "$prev" in
                -b)
                    local branches
                    branches=$(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)
                    COMPREPLY=($(compgen -W "$branches" -- "$cur"))
                    ;;
                *)
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-b" -- "$cur"))
                    fi
                    ;;
            esac
            ;;
        dir)
            local worktrees
            worktrees=$(sprout list 2>/dev/null)
            COMPREPLY=($(compgen -W "$worktrees" -- "$cur"))
            ;;
        list)
            if [[ "$cur" == -* ]]; then
                COMPREPLY=($(compgen -W "--verbose --full -v" -- "$cur"))
            fi
            ;;
        rm)
            case "$prev" in
                rm)
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-f --force" -- "$cur"))
                    else
                        local worktrees
                        worktrees=$(sprout list 2>/dev/null)
                        COMPREPLY=($(compgen -W "$worktrees" -- "$cur"))
                    fi
                    ;;
                *)
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-f --force" -- "$cur"))
                    else
                        local worktrees
                        worktrees=$(sprout list 2>/dev/null)
                        COMPREPLY=($(compgen -W "$worktrees" -- "$cur"))
                    fi
                    ;;
            esac
            ;;
        open)
            case "$prev" in
                -e|--editor)
                    # Complete with available commands for editor
                    COMPREPLY=($(compgen -c -- "$cur"))
                    ;;
                *)
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-e --editor" -- "$cur"))
                    else
                        local worktrees
                        worktrees=$(sprout list 2>/dev/null)
                        COMPREPLY=($(compgen -W "$worktrees" -- "$cur"))
                    fi
                    ;;
            esac
            ;;
        start)
            case "$prev" in
                -b)
                    local branches
                    branches=$(git branch -a --format='%(refname:short)' 2>/dev/null | sed 's|^origin/||' | sort -u)
                    COMPREPLY=($(compgen -W "$branches" -- "$cur"))
                    ;;
                -e|--editor)
                    COMPREPLY=($(compgen -c -- "$cur"))
                    ;;
                *)
                    if [[ "$cur" == -* ]]; then
                        COMPREPLY=($(compgen -W "-b -e --editor" -- "$cur"))
                    fi
                    ;;
            esac
            ;;
        config)
            if [[ $cword -eq 2 ]]; then
                COMPREPLY=($(compgen -W "$config_subcmds" -- "$cur"))
            elif [[ $cword -eq 3 ]]; then
                case "${words[2]}" in
                    set|get)
                        COMPREPLY=($(compgen -W "$config_keys" -- "$cur"))
                        ;;
                esac
            fi
            ;;
    esac
}

complete -F _sprout sprout
