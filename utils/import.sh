#!/usr/bin/env bash
# Import is an easy way to include other modules.

# Set up an import load path
__import_path=(
    "$__repo_root"
)

declare -A __import_cache
__import_cache=(
    # Only include bootstrapped items in initial cache
    [utils/logger]=1
    [utils/import]=1
)

function import() {
    local file=$1
    if [[ ! -e "$file.sh" ]]; then
        logger.error "Cannot import '$file.sh': File does not exist"
    fi
    # Only import once
    if [[ -n "${__import_cache[$file]+x}" ]]; then
        return
    fi

    # Allow arbitrary module imports.
    # shellcheck disable=SC1090
    source "$file.sh"
    __import_cache[$file]=1
}

function register_import_path() {
    __import_path+=("$@")
}
