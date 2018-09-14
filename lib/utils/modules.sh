#!/usr/bin/env bash
# Import is an easy way to include other modules.

# Requires the following modules to already be sourced:
# * utils/logger
# * utils/map
# * utils/string

# Set up an import load path
declare -ag __import_paths=()

declare -Ag __import_cache=(
    # Only include bootstrapped items in initial cache
    [utils/modules]=1
    [utils/logger]=1
    [utils/map]=1
    [utils/string]=1
)

declare -ig __warning_limit=3

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
    logger.trace "Importing '$import_path'..."
    local rc=0
    local module_name=${import_path##*/}
    modules._load "$file" "$module_name" || rc=$?
    if [[ $rc != 0 ]]; then
        logger.error "Cannot import '$file': Error occurred during source."
        unset __import_cache["$import_path"]
        return $rc
    fi
    modules._cache_import "$import_path" 1
    logger.trace "Done importing '$import_path'!"
    if declare -F "$module_name".init &>/dev/null; then
        logger.trace "Initializing '$module_name'..."
        "$module_name".init
        logger.trace "Done initializing '$module_name'!"
    fi
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
    if [[ "${BASHTION_BOOTSTRAPPED:-false}" != true ]]; then
        # Allow arbitrary module imports.
        # shellcheck disable=SC1090
        source "$file" || return $?
    else
        # Run extra checks to warn for badly namespaced functions
        # Only run this after bootstrapping to include helpful debug messages for library internals

        modules._vet "$module_name" "$file"
        # Allow arbitrary module imports.
        # shellcheck disable=SC1090
        source "$file" || return $?
    fi
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

function modules.set_warning_limit() {
    __warning_limit=${1:-3}
}

function modules._vet() {
    local module_name=$1
    local file_path=$2

    local lines
    lines=$(< "$file_path")
    local func_names=()
    local func_name=$'([^\n(){}[:space:]]+)'
    local func_footer='([[:space:]]*\(\))'
    local tmp=$lines
    while [[ "$tmp" =~ (function ${func_name}${func_footer}?|${func_name}${func_footer})[:space:]*\{* ]]; do
        if [[ -n "${BASH_REMATCH[2]}" ]]; then
            func_names+=("${BASH_REMATCH[2]}")
        else
            func_names+=("${BASH_REMATCH[4]}")
        fi
        tmp=${tmp/${BASH_REMATCH[0]}/}
    done

    declare -i warnings=0
    declare -ir warning_log_limit=${__warning_limit}
    if [[ -n "${func_names+x}" ]]; then
        for func in "${func_names[@]}"; do
            if [[ "$func" != "$module_name" && "$func" != "$module_name".* ]]; then
                if (( warnings < warning_log_limit )); then
                    logger.warn "Functions should be namespaced with the module's name, but found: '$func'"
                    logger.warn "Remove this warning by renaming the function to include the prefix '$module_name.'"
                fi
                warnings+=1
            fi
        done
    fi
    if (( warnings > warning_log_limit )); then
        logger.warn "Suppressed $((warnings - warning_log_limit)) additional function name warnings."
    fi
}
