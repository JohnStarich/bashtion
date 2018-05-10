#!/usr/bin/env bash
# Import is an easy way to include other modules.

# Set up an import load path
declare -ag __import_paths=()

declare -Ag __import_cache=(
    # Only include bootstrapped items in initial cache
    [utils/logger]=1
    [utils/import]=1
)

alias import=modules.import
function modules.import() {
    local import_path=${1%.sh}
    # Only import once
    if [[ -n "${__import_cache["$import_path"]:+x}" ]]; then
        logger.trace "skipping cached import '$import_path'"
        return
    fi
    local file=''
    if [[ -e "$import_path.sh" ]]; then
        file="$import_path.sh"
    elif [[ -e "$import_path" ]]; then
        file="$import_path"
    else
        for path in "${__import_paths[@]}"; do
            if [[ -e "$path/$import_path.sh" ]]; then
                file=$path/$import_path.sh
                break
            elif [[ -e "$path/$import_path" ]]; then
                file=$path/$import_path
            fi
        done
        if [[ ! -e "$file" ]]; then
            logger.error "Cannot import '$import_path': File does not exist"
            return 1
        fi
    fi

    modules._cache_import "$import_path" 0
    logger.trace "importing '$import_path'..."
    local rc=0
    modules._load "$file" "${import_path##*/}" || rc=$?
    if [[ $rc != 0 ]]; then
        logger.error "Cannot import '$file': Error occurred during source."
        unset __import_cache["$import_path"]
        return $rc
    fi
    modules._cache_import "$import_path" 1
    logger.trace "done importing '$import_path'!"
}

function modules._cache_import() {
    local import_path=$1
    local import_status=${2:-1}
    __import_cache["$import_path"]=$import_status
}

function modules._load() {
    local file=$1
    local module_name=$2
    if [[ "$module_name" =~ ' ' ]]; then
        logger.fatal "Cannot load module name with spaces: '$module_name'"
        exit 2
    fi
    # Allow arbitrary module imports.
    # shellcheck disable=SC1090
    source "$file" || return $?
    modules._create_module_helper "$module_name"
}

function modules.identifier_is_available() {
    if [[ $# == 0 ]]; then
        logger.error 'Usage: modules.identifier_is_available NAME'
        return 2
    fi
    local name=$1
    type "$name" &>/dev/null && \
        logger.trace "Identifier is already a type: $name" && \
        return 1
    declare -p "$name" &>/dev/null && \
        logger.trace "Identifier is already a var: $name" && \
        return 1
    return 0
}

function modules._create_module_helper() {
    local module_name=$1
    local clobber=${clobber:-false}
    if [[ "$clobber" == true ]] || modules.identifier_is_available "$module_name"; then
        logger.trace "Creating module helper: '$module_name'"
        eval '
        function '"$module_name"'() {
            modules._module_helper_stub "'"$module_name"'" "$@"
        }
        '
    fi
    if modules.identifier_is_available "$module_name".usage; then
        logger.trace "Creating module helper: '$module_name.usage'"
        eval '
        function '"$module_name.usage"'() {
            modules._module_helper_stub "'"$module_name"'" "$@"
        }
        '
    fi
}

function modules._module_helper_stub() {
    local module_name=$1; shift
    local options
    options=$(compgen -A function -X "$module_name._*" "$module_name.")
    if [[ -z "$options" ]]; then
        logger.error "No subcommands available for $module_name"
        return 1
    else
        printf 'Available options for %s:\n' "$module_name"
        printf '%s\n' "$options"
    fi
}

function modules.register_import_path() {
    __import_paths+=("$@")
}

function modules.init() {
    clobber=true modules._create_module_helper logger
    clobber=true modules._create_module_helper modules
}
