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
    [ -f "$PROJECT_ROOT/lib/commands/rm.sh" ] && \
    [ -f "$PROJECT_ROOT/lib/commands/open.sh" ]
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
