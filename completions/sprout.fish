# Fish completion for sprout - Git worktree management utility

# Helper: list worktree names
function __sprout_worktrees
    sprout list 2>/dev/null
end

# Helper: list git branches
function __sprout_branches
    git branch -a --format='%(refname:short)' 2>/dev/null | string replace -r '^origin/' '' | sort -u
end

# Helper: check if a subcommand has been given
function __sprout_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

# Helper: check if a specific subcommand is active
function __sprout_using_command
    set -l cmd (commandline -opc)
    test (count $cmd) -ge 2; and test $cmd[2] = $argv[1]
end

# Helper: check if config subcommand is active and no config action given yet
function __sprout_config_needs_subcmd
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 2; and test $cmd[2] = config
end

# Helper: check if config set/get is active and needs key
function __sprout_config_needs_key
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 3; and test $cmd[2] = config; and contains -- $cmd[3] set get
end

# Disable file completions for sprout
complete -c sprout -f

# Top-level commands
complete -c sprout -n __sprout_needs_command -a add -d 'Create a new worktree'
complete -c sprout -n __sprout_needs_command -a dir -d 'Print the directory path of a worktree'
complete -c sprout -n __sprout_needs_command -a list -d 'List all worktrees'
complete -c sprout -n __sprout_needs_command -a rm -d 'Remove a worktree'
complete -c sprout -n __sprout_needs_command -a open -d 'Open a worktree with the configured editor'
complete -c sprout -n __sprout_needs_command -a start -d 'Create a new worktree and open it in the editor'
complete -c sprout -n __sprout_needs_command -a checkout -d 'Checkout an existing branch into a new worktree'
complete -c sprout -n __sprout_needs_command -a config -d 'Manage sprout configuration'
complete -c sprout -n __sprout_needs_command -a help -d 'Show help message'

# add: -b <branch>
complete -c sprout -n '__sprout_using_command add' -s b -d 'Checkout a specific branch' -xa '(__sprout_branches)'

# dir: complete worktree names
complete -c sprout -n '__sprout_using_command dir' -a '(__sprout_worktrees)'

# list: flags
complete -c sprout -n '__sprout_using_command list' -l verbose -d 'Show full paths'
complete -c sprout -n '__sprout_using_command list' -l full -d 'Show full paths'
complete -c sprout -n '__sprout_using_command list' -s v -d 'Show full paths'

# rm: worktree names + force flag
complete -c sprout -n '__sprout_using_command rm' -a '(__sprout_worktrees)'
complete -c sprout -n '__sprout_using_command rm' -s f -l force -d 'Force removal'

# open: worktree names + editor flag
complete -c sprout -n '__sprout_using_command open' -a '(__sprout_worktrees)'
complete -c sprout -n '__sprout_using_command open' -s e -l editor -d 'Use specific editor'

# checkout: branch names
complete -c sprout -n '__sprout_using_command checkout' -a '(__sprout_branches)'

# start: -b <branch> + -e <editor>
complete -c sprout -n '__sprout_using_command start' -s b -d 'Checkout a specific branch' -xa '(__sprout_branches)'
complete -c sprout -n '__sprout_using_command start' -s e -l editor -d 'Use specific editor'

# config: subcommands
complete -c sprout -n __sprout_config_needs_subcmd -a set -d 'Set a configuration value'
complete -c sprout -n __sprout_config_needs_subcmd -a get -d 'Get a configuration value'
complete -c sprout -n __sprout_config_needs_subcmd -a show -d 'Show all configuration'

# config set/get: keys
complete -c sprout -n __sprout_config_needs_key -a 'worktree_dir editor'
