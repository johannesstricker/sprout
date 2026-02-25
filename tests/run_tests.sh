#!/bin/bash
# Test runner for sprout

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🧪 Running Sprout Tests"
echo "======================="
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run a test
run_test() {
    local test_name="$1"
    local test_func="$2"

    echo -n "Testing: $test_name... "

    if $test_func > /dev/null 2>&1; then
        echo "✓"
        ((TESTS_PASSED++))
        return 0
    else
        echo "✗"
        ((TESTS_FAILED++))
        echo "  Error in: $test_name"
        return 0  # Don't fail the whole script
    fi
}

# Test: Check if main script exists and is executable
test_main_script_exists() {
    [ -x "$PROJECT_ROOT/bin/sprout" ]
}

# Test: Check if all library files exist
test_libraries_exist() {
    [ -f "$PROJECT_ROOT/lib/config.sh" ] && \
    [ -f "$PROJECT_ROOT/lib/utils.sh" ] && \
    [ -f "$PROJECT_ROOT/lib/hooks.sh" ] && \
    [ -f "$PROJECT_ROOT/lib/commands/add.sh" ] && \
    [ -f "$PROJECT_ROOT/lib/commands/dir.sh" ] && \
    [ -f "$PROJECT_ROOT/lib/commands/list.sh" ] && \
    [ -f "$PROJECT_ROOT/lib/commands/rm.sh" ] && \
    [ -f "$PROJECT_ROOT/lib/commands/open.sh" ] && \
    [ -f "$PROJECT_ROOT/lib/commands/start.sh" ] && \
    [ -f "$PROJECT_ROOT/lib/commands/checkout.sh" ]
}

# Test: Help command works
test_help_command() {
    "$PROJECT_ROOT/bin/sprout" help > /dev/null
}

# Test: Config initialization
test_config_init() {
    # Create a temporary test environment
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    # Initialize config
    source "$PROJECT_ROOT/lib/config.sh"
    init_config

    # Check if config file was created
    [ -f "$temp_dir/.sproutrc" ]

    # Cleanup
    rm -rf "$temp_dir"
}

# Test: Config get/set
test_config_operations() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    source "$PROJECT_ROOT/lib/config.sh"

    # Test set
    set_config "test_key" "test_value"

    # Test get
    local value
    value=$(get_config "test_key")
    [ "$value" = "test_value" ]

    # Cleanup
    rm -rf "$temp_dir"
}

# Test: Syntax check all bash files
test_syntax_check() {
    for file in "$PROJECT_ROOT"/bin/sprout \
                "$PROJECT_ROOT"/lib/*.sh \
                "$PROJECT_ROOT"/lib/commands/*.sh; do
        bash -n "$file" || return 1
    done
}

# Test: List command with no worktrees
test_list_empty() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    # Create a test repo
    local test_repo="$temp_dir/test-repo"
    git init "$test_repo" > /dev/null 2>&1
    cd "$test_repo"

    # Initialize sprout config
    source "$PROJECT_ROOT/lib/config.sh"
    init_config > /dev/null 2>&1

    # List should succeed with no output
    local output
    output=$("$PROJECT_ROOT/bin/sprout" list 2>&1)
    local exit_code=$?

    # Cleanup
    cd "$temp_dir"
    rm -rf "$test_repo"
    rm -rf "$temp_dir"

    # Check exit code is 0 and output is empty
    [ $exit_code -eq 0 ] && [ -z "$output" ]
}

# Test: List command output is sorted
test_list_sorted() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    # Create a test repo
    local test_repo="$temp_dir/test-repo"
    git init "$test_repo" > /dev/null 2>&1
    cd "$test_repo"
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1

    # Create initial commit
    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    # Initialize sprout config
    source "$PROJECT_ROOT/lib/config.sh"
    init_config > /dev/null 2>&1
    set_config "worktree_dir" "$temp_dir/worktrees"

    # Create worktrees in non-alphabetical order
    "$PROJECT_ROOT/bin/sprout" add "zebra" > /dev/null 2>&1 || true
    "$PROJECT_ROOT/bin/sprout" add "alpha" > /dev/null 2>&1 || true
    "$PROJECT_ROOT/bin/sprout" add "middle" > /dev/null 2>&1 || true

    # Get list output
    local output
    output=$("$PROJECT_ROOT/bin/sprout" list 2>&1)

    # Check if output is sorted (alpha, middle, zebra)
    local expected="alpha
middle
zebra"

    # Cleanup
    cd "$temp_dir"
    rm -rf "$test_repo" "$temp_dir/worktrees"
    rm -rf "$temp_dir"

    # Compare output
    [ "$output" = "$expected" ]
}

# Test: List command with --verbose flag
test_list_verbose() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    # Create a test repo
    local test_repo="$temp_dir/test-repo"
    git init "$test_repo" > /dev/null 2>&1
    cd "$test_repo"
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1

    # Create initial commit
    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    # Initialize sprout config
    source "$PROJECT_ROOT/lib/config.sh"
    init_config > /dev/null 2>&1
    set_config "worktree_dir" "$temp_dir/worktrees"

    # Create a worktree
    "$PROJECT_ROOT/bin/sprout" add "test-wt" > /dev/null 2>&1 || true

    # Get verbose output
    local output
    output=$("$PROJECT_ROOT/bin/sprout" list --verbose 2>&1)

    # Verbose output should contain full path
    local has_full_path=false
    if [[ "$output" == *"/worktrees/"* ]]; then
        has_full_path=true
    fi

    # Cleanup
    cd "$temp_dir"
    rm -rf "$test_repo" "$temp_dir/worktrees"
    rm -rf "$temp_dir"

    # Check if full path was shown
    [ "$has_full_path" = true ]
}

# Test: List command with slash in worktree name
test_list_with_slash() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    # Create a test repo
    local test_repo="$temp_dir/test-repo"
    git init "$test_repo" > /dev/null 2>&1
    cd "$test_repo"
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1

    # Create initial commit
    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    # Initialize sprout config
    source "$PROJECT_ROOT/lib/config.sh"
    init_config > /dev/null 2>&1
    set_config "worktree_dir" "$temp_dir/worktrees"

    # Create worktrees with slashes in names
    "$PROJECT_ROOT/bin/sprout" add "feat/add-new-feature" > /dev/null 2>&1 || true
    "$PROJECT_ROOT/bin/sprout" add "fix/bug-123" > /dev/null 2>&1 || true
    "$PROJECT_ROOT/bin/sprout" add "simple" > /dev/null 2>&1 || true

    # Get list output
    local output
    output=$("$PROJECT_ROOT/bin/sprout" list 2>&1)

    # Convert to array for checking
    local -a lines
    mapfile -t lines <<< "$output"

    # Should have 3 worktrees
    local count=${#lines[@]}

    # Check that full names with slashes are preserved
    local has_feat=false
    local has_fix=false
    local has_simple=false

    for line in "${lines[@]}"; do
        if [[ "$line" == "feat/add-new-feature" ]]; then
            has_feat=true
        elif [[ "$line" == "fix/bug-123" ]]; then
            has_fix=true
        elif [[ "$line" == "simple" ]]; then
            has_simple=true
        fi
    done

    # Cleanup
    cd "$temp_dir"
    rm -rf "$test_repo" "$temp_dir/worktrees"
    rm -rf "$temp_dir"

    # Verify all worktrees were found with correct names
    [ "$count" -eq 3 ] && [ "$has_feat" = true ] && [ "$has_fix" = true ] && [ "$has_simple" = true ]
}

# Test: Start command creates worktree and opens editor
test_start_creates_worktree() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    # Create a test repo
    local test_repo="$temp_dir/test-repo"
    git init "$test_repo" > /dev/null 2>&1
    cd "$test_repo"
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1

    # Create initial commit
    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    # Get the actual default branch name (master or main)
    local default_branch
    default_branch=$(git rev-parse --abbrev-ref HEAD)

    # Initialize sprout config with a dummy editor (true always succeeds)
    source "$PROJECT_ROOT/lib/config.sh"
    init_config > /dev/null 2>&1
    set_config "worktree_dir" "$temp_dir/worktrees"
    set_config "editor" "true"

    # Run start command with explicit branch
    local output
    output=$("$PROJECT_ROOT/bin/sprout" start "test-wt" -b "$default_branch" 2>&1)
    local exit_code=$?

    # Check worktree was created
    local worktree_exists=false
    if [[ -d "$temp_dir/worktrees/test-repo/test-wt" ]]; then
        worktree_exists=true
    fi

    # Cleanup
    cd "$temp_dir"
    rm -rf "$test_repo" "$temp_dir/worktrees"
    rm -rf "$temp_dir"

    [ $exit_code -eq 0 ] && [ "$worktree_exists" = true ]
}

# Test: Start command with -b flag
test_start_with_branch() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    # Create a test repo with a develop branch
    local test_repo="$temp_dir/test-repo"
    git init "$test_repo" > /dev/null 2>&1
    cd "$test_repo"
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1

    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    git branch develop > /dev/null 2>&1

    # Initialize sprout config
    source "$PROJECT_ROOT/lib/config.sh"
    init_config > /dev/null 2>&1
    set_config "worktree_dir" "$temp_dir/worktrees"
    set_config "editor" "true"

    # Run start with -b flag
    local output
    output=$("$PROJECT_ROOT/bin/sprout" start "my-feature" -b develop 2>&1)
    local exit_code=$?

    # Check worktree was created
    local worktree_exists=false
    if [[ -d "$temp_dir/worktrees/test-repo/my-feature" ]]; then
        worktree_exists=true
    fi

    # Cleanup
    cd "$temp_dir"
    rm -rf "$test_repo" "$temp_dir/worktrees"
    rm -rf "$temp_dir"

    [ $exit_code -eq 0 ] && [ "$worktree_exists" = true ]
}

# Test: Start command fails without name
test_start_missing_name() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    local test_repo="$temp_dir/test-repo"
    git init "$test_repo" > /dev/null 2>&1
    cd "$test_repo"
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1

    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    source "$PROJECT_ROOT/lib/config.sh"
    init_config > /dev/null 2>&1

    # Run start without a name - should fail
    "$PROJECT_ROOT/bin/sprout" start > /dev/null 2>&1
    local exit_code=$?

    # Cleanup
    cd "$temp_dir"
    rm -rf "$test_repo"
    rm -rf "$temp_dir"

    [ $exit_code -ne 0 ]
}

# Test: Checkout an existing local branch
test_checkout_local_branch() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    # Create a test repo
    local test_repo="$temp_dir/test-repo"
    git init "$test_repo" > /dev/null 2>&1
    cd "$test_repo"
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1

    # Create initial commit
    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    # Create a local branch
    git branch develop > /dev/null 2>&1

    # Initialize sprout config
    source "$PROJECT_ROOT/lib/config.sh"
    init_config > /dev/null 2>&1
    set_config "worktree_dir" "$temp_dir/worktrees"

    # Run checkout
    local output
    output=$("$PROJECT_ROOT/bin/sprout" checkout develop 2>&1)
    local exit_code=$?

    # Verify worktree exists and branch is checked out
    local worktree_exists=false
    local correct_branch=false
    if [[ -d "$temp_dir/worktrees/test-repo/develop" ]]; then
        worktree_exists=true
        local branch_name
        branch_name=$(cd "$temp_dir/worktrees/test-repo/develop" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [[ "$branch_name" == "develop" ]]; then
            correct_branch=true
        fi
    fi

    # Cleanup
    cd "$temp_dir"
    rm -rf "$test_repo" "$temp_dir/worktrees"
    rm -rf "$temp_dir"

    [ $exit_code -eq 0 ] && [ "$worktree_exists" = true ] && [ "$correct_branch" = true ]
}

# Test: Checkout a remote-only branch
test_checkout_remote_only_branch() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    # Create a bare remote repo
    local bare_repo="$temp_dir/remote.git"
    git init --bare "$bare_repo" > /dev/null 2>&1

    # Create a local repo and push to the bare remote
    local source_repo="$temp_dir/source-repo"
    git init "$source_repo" > /dev/null 2>&1
    cd "$source_repo"
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1

    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    git remote add origin "$bare_repo" > /dev/null 2>&1
    git push origin HEAD > /dev/null 2>&1

    # Create a branch and push it to remote only
    git checkout -b feature-remote > /dev/null 2>&1
    echo "feature" > feature.txt
    git add feature.txt > /dev/null 2>&1
    git commit -m "Feature commit" > /dev/null 2>&1
    git push origin feature-remote > /dev/null 2>&1

    # Clone the repo fresh (so feature-remote is remote-only)
    local test_repo="$temp_dir/test-repo"
    git clone "$bare_repo" "$test_repo" > /dev/null 2>&1
    cd "$test_repo"
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1

    # Initialize sprout config
    source "$PROJECT_ROOT/lib/config.sh"
    init_config > /dev/null 2>&1
    set_config "worktree_dir" "$temp_dir/worktrees"

    # Run checkout for the remote-only branch
    local output
    output=$("$PROJECT_ROOT/bin/sprout" checkout feature-remote 2>&1)
    local exit_code=$?

    # Verify worktree exists
    local worktree_exists=false
    local correct_branch=false
    if [[ -d "$temp_dir/worktrees/test-repo/feature-remote" ]]; then
        worktree_exists=true
        local branch_name
        branch_name=$(cd "$temp_dir/worktrees/test-repo/feature-remote" && git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [[ "$branch_name" == "feature-remote" ]]; then
            correct_branch=true
        fi
    fi

    # Cleanup
    cd "$temp_dir"
    rm -rf "$bare_repo" "$source_repo" "$test_repo" "$temp_dir/worktrees"
    rm -rf "$temp_dir"

    [ $exit_code -eq 0 ] && [ "$worktree_exists" = true ] && [ "$correct_branch" = true ]
}

# Test: Checkout fails for nonexistent branch
test_checkout_fails_nonexistent() {
    local temp_dir=$(mktemp -d)
    export HOME="$temp_dir"

    local test_repo="$temp_dir/test-repo"
    git init "$test_repo" > /dev/null 2>&1
    cd "$test_repo"
    git config user.name "Test User" > /dev/null 2>&1
    git config user.email "test@test.com" > /dev/null 2>&1

    echo "test" > README.md
    git add README.md > /dev/null 2>&1
    git commit -m "Initial commit" > /dev/null 2>&1

    source "$PROJECT_ROOT/lib/config.sh"
    init_config > /dev/null 2>&1

    # Run checkout for a branch that doesn't exist - should fail
    "$PROJECT_ROOT/bin/sprout" checkout no-such-branch > /dev/null 2>&1
    local exit_code=$?

    # Cleanup
    cd "$temp_dir"
    rm -rf "$test_repo"
    rm -rf "$temp_dir"

    [ $exit_code -ne 0 ]
}

# Run all tests
echo "Core Tests:"
echo "-----------"
run_test "Main script exists and is executable" "test_main_script_exists"
run_test "All library files exist" "test_libraries_exist"
run_test "Help command works" "test_help_command"
run_test "Bash syntax is valid" "test_syntax_check"

echo ""
echo "Configuration Tests:"
echo "-------------------"
run_test "Config initialization" "test_config_init"
run_test "Config get/set operations" "test_config_operations"

echo ""
echo "List Command Tests:"
echo "-------------------"
run_test "List command with no worktrees" "test_list_empty"
run_test "List command output is sorted" "test_list_sorted"
run_test "List command with --verbose flag" "test_list_verbose"
run_test "List command with slash in worktree name" "test_list_with_slash"

echo ""
echo "Start Command Tests:"
echo "--------------------"
run_test "Start command creates worktree and opens editor" "test_start_creates_worktree"
run_test "Start command with -b flag" "test_start_with_branch"
run_test "Start command fails without name" "test_start_missing_name"

echo ""
echo "Checkout Command Tests:"
echo "-----------------------"
run_test "Checkout an existing local branch" "test_checkout_local_branch"
run_test "Checkout a remote-only branch" "test_checkout_remote_only_branch"
run_test "Checkout fails for nonexistent branch" "test_checkout_fails_nonexistent"

echo ""
echo "======================="
echo "Test Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed!"
    exit 1
fi
