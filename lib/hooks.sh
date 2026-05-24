#!/bin/bash
# Hook management for sprout
#
# Init hooks let you customise a worktree after it is created. Sprout looks
# for hooks under .sprout/ in the source repository, in priority order:
#
#   1. .sprout/init.yaml  - declarative YAML hook (preferred)
#   2. .sprout/init       - legacy executable bash hook (fallback)
#
# See examples/init-node.yaml and examples/init-python.yaml.

HOOK_PATH_YAML=".sprout/init.yaml"
HOOK_PATH_SH=".sprout/init"

# Execute the init hook for a freshly-created worktree, if one exists.
run_init_hook() {
    local worktree_path="$1"

    local repo_root
    repo_root=$(get_repo_root) || return 1

    local yaml_hook="${repo_root}/${HOOK_PATH_YAML}"
    local sh_hook="${repo_root}/${HOOK_PATH_SH}"

    if [[ -f "$yaml_hook" ]]; then
        _run_yaml_hook "$worktree_path" "$repo_root" "$yaml_hook"
    elif [[ -f "$sh_hook" ]]; then
        _run_sh_hook "$worktree_path" "$repo_root" "$sh_hook"
    else
        return 0
    fi
}

# Run the legacy executable bash hook.
_run_sh_hook() {
    local worktree_path="$1"
    local repo_root="$2"
    local hook_file="$3"

    chmod +x "$hook_file"

    (
        export SPROUT_WORKTREE_PATH="$worktree_path"
        export SPROUT_REPO_ROOT="$repo_root"
        export SPROUT_WORKTREE_NAME="$(basename "$worktree_path")"

        cd "$worktree_path"

        if ! bash "$hook_file"; then
            echo "Error: Init hook failed" >&2
            return 1
        fi
    ) || return 1
}

# Run the declarative YAML hook.
_run_yaml_hook() {
    local worktree_path="$1"
    local repo_root="$2"
    local hook_file="$3"

    if ! command -v yq >/dev/null 2>&1; then
        echo "Error: yq is required to parse $HOOK_PATH_YAML but was not found on PATH." >&2
        echo "Install yq: https://github.com/mikefarah/yq#install (or 'pip install yq')." >&2
        return 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
        echo "Error: jq is required to parse $HOOK_PATH_YAML but was not found on PATH." >&2
        return 1
    fi

    local json
    json=$(_yaml_to_json "$hook_file") || {
        echo "Error: failed to parse $hook_file" >&2
        return 1
    }

    export SPROUT_WORKTREE_PATH="$worktree_path"
    export SPROUT_REPO_ROOT="$repo_root"
    export SPROUT_WORKTREE_NAME="$(basename "$worktree_path")"

    _run_copy_steps "$json" "$worktree_path" "$repo_root" || return 1
    _run_run_steps  "$json" "$worktree_path" "$repo_root" || return 1
}

# Convert a YAML file to compact JSON. Works with both python-yq and
# mikefarah's go-yq.
_yaml_to_json() {
    local file="$1"
    # mikefarah/yq v4+ supports -o=json. python-yq does not, but emits JSON
    # by default. Try mikefarah first; fall back to the python-yq form.
    local out
    if out=$(yq -o=json -I=0 '.' "$file" 2>/dev/null); then
        printf '%s' "$out"
        return 0
    fi
    yq -c '.' "$file"
}

_run_copy_steps() {
    local json="$1"
    local worktree_path="$2"
    local repo_root="$3"

    local count
    count=$(jq -r '.copy // [] | length' <<<"$json") || return 1

    local i
    for ((i = 0; i < count; i++)); do
        local step
        step=$(jq -c ".copy[$i]" <<<"$json") || return 1
        _run_copy_step "$step" "$worktree_path" "$repo_root" || return 1
    done
}

_run_copy_step() {
    local step="$1"
    local worktree_path="$2"
    local repo_root="$3"

    local kind
    kind=$(jq -r 'type' <<<"$step")

    local src dest optional name has_src
    if [[ "$kind" == "string" ]]; then
        src=$(jq -r '.' <<<"$step")
        dest=""
        optional="false"
        name=""
    elif [[ "$kind" == "object" ]]; then
        has_src=$(jq -r 'has("src")' <<<"$step")
        if [[ "$has_src" != "true" ]]; then
            echo "Error: copy entry missing required 'src'" >&2
            return 1
        fi
        src=$(jq -r '.src' <<<"$step")
        dest=$(jq -r '.dest // ""' <<<"$step")
        optional=$(jq -r '.optional // false' <<<"$step")
        name=$(jq -r '.name // ""' <<<"$step")
    else
        echo "Error: copy entry must be a string or object, got $kind" >&2
        return 1
    fi

    if [[ -z "$src" ]]; then
        echo "Error: copy entry has empty 'src'" >&2
        return 1
    fi

    local is_glob=false
    if [[ "$src" == *"*"* || "$src" == *"?"* || "$src" == *"["* ]]; then
        is_glob=true
    fi

    # Resolve src relative to repo root. Globs expand via shell with nullglob;
    # literal paths are checked for existence explicitly (nullglob does not
    # remove non-matching literal paths).
    local -a matches=()
    if [[ "$is_glob" == "true" ]]; then
        local restore_nullglob
        restore_nullglob=$(shopt -p nullglob)
        shopt -s nullglob
        # shellcheck disable=SC2206
        matches=( ${repo_root}/${src} )
        eval "$restore_nullglob"
    elif [[ -e "${repo_root}/${src}" ]]; then
        matches=( "${repo_root}/${src}" )
    fi

    if [[ ${#matches[@]} -eq 0 ]]; then
        if [[ "$optional" == "true" ]]; then
            return 0
        fi
        echo "Error: copy source not found: $src" >&2
        return 1
    fi

    local match relpath target
    for match in "${matches[@]}"; do
        relpath="${match#${repo_root}/}"
        if [[ -z "$dest" ]]; then
            target="${worktree_path}/${relpath}"
        elif [[ "$is_glob" == "true" ]]; then
            target="${worktree_path}/${dest%/}/$(basename "$match")"
        else
            target="${worktree_path}/${dest}"
        fi

        mkdir -p "$(dirname "$target")" || return 1
        if ! cp -R "$match" "$target"; then
            echo "Error: failed to copy $match -> $target" >&2
            return 1
        fi
    done

    if [[ -n "$name" ]]; then
        echo "✓ $name"
    elif [[ ${#matches[@]} -eq 1 ]]; then
        echo "✓ Copied ${matches[0]#${repo_root}/}"
    else
        echo "✓ Copied ${#matches[@]} files matching $src"
    fi
}

_run_run_steps() {
    local json="$1"
    local worktree_path="$2"
    local repo_root="$3"

    local count
    count=$(jq -r '.run // [] | length' <<<"$json") || return 1

    local i
    for ((i = 0; i < count; i++)); do
        local step
        step=$(jq -c ".run[$i]" <<<"$json") || return 1
        _run_run_step "$step" "$worktree_path" "$repo_root" || return 1
    done
}

_run_run_step() {
    local step="$1"
    local worktree_path="$2"
    local repo_root="$3"

    local kind
    kind=$(jq -r 'type' <<<"$step")

    local cmd allow_failure name has_cmd
    if [[ "$kind" == "string" ]]; then
        cmd=$(jq -r '.' <<<"$step")
        allow_failure="false"
        name=""
    elif [[ "$kind" == "object" ]]; then
        # Use has() so that a literal command like `cmd: false` (the unix
        # utility) is not mistaken for a missing key.
        has_cmd=$(jq -r 'has("cmd")' <<<"$step")
        if [[ "$has_cmd" != "true" ]]; then
            echo "Error: run entry missing required 'cmd'" >&2
            return 1
        fi
        cmd=$(jq -r '.cmd' <<<"$step")
        allow_failure=$(jq -r '.allow_failure // false' <<<"$step")
        name=$(jq -r '.name // ""' <<<"$step")
    else
        echo "Error: run entry must be a string or object, got $kind" >&2
        return 1
    fi

    if [[ -n "$name" ]]; then
        echo "→ $name"
    else
        echo "→ $cmd"
    fi

    (
        cd "$worktree_path"
        bash -c "$cmd"
    )
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        if [[ "$allow_failure" == "true" ]]; then
            echo "  (ignored: exit $rc)" >&2
            return 0
        fi
        echo "Error: command failed (exit $rc): $cmd" >&2
        return 1
    fi
}
