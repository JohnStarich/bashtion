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

alias import=modules.import
function modules.import() {
    local file=$1
    # Only import once
    if [[ -n "${__import_cache[$file]+x}" ]]; then
        return
    fi
    if [[ "${file:0:1}" != / ]]; then
        for path in "${__import_path[@]}"; do
            if [[ -e "$path/$file.sh" ]]; then
                file=$path/$file
                break
            fi
        done
    fi
    if [[ ! -e "$file.sh" ]]; then
        logger.error "Cannot import '$file.sh': File does not exist"
    fi

    # Allow arbitrary module imports.
    # shellcheck disable=SC1090
    if ! source "$file.sh"; then
        logger.error "Cannot import '$file.sh': Error occurred during source."
    fi
    __import_cache[$file]=1
}

function modules.register_import_path() {
    __import_path+=("$@")
}
