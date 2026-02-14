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
    [ -f "$PROJECT_ROOT/lib/commands/start.sh" ]
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
