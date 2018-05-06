#!/usr/bin/env bash
# Import is an easy way to include other modules.

# Set up an import load path
__import_paths=(
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
    local import_path=$1
    # Only import once
    if [[ -n "${__import_cache["$import_path"]:+x}" ]]; then
        return
    fi
    local file="$import_path"
    if [[ "${import_path:0:1}" != / ]]; then
        for path in "${__import_paths[@]}"; do
            if [[ -e "$path/$import_path.sh" ]]; then
                file=$path/$import_path
                break
            fi
        done
    fi
    if [[ ! -e "$file.sh" ]]; then
        logger.error "Cannot import '$file.sh': File does not exist"
    fi

    __import_cache["$import_path"]=0
    if ! modules._load "$file.sh" "${import_path##*/}"; then
        logger.error "Cannot import '$file.sh': Error occurred during source."
        unset __import_cache['$'import_path]
    fi
    __import_cache["$import_path"]=1
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

function modules._create_module_helper() {
    local module_name=$1
    local clobber=${clobber:-false}
    if [[ "$clobber" != true ]] && type "$module_name" &>/dev/null; then
        return
    fi
    eval '
    function '"$module_name"'() {
        modules._module_helper_stub "'"$module_name"'" "$@"
    }
    '
}

function modules._module_helper_stub() {
    local module_name=$1; shift
    if type "$module_name".usage &>/dev/null; then
        "$module_name".usage "$@"
    else
        local options
        options=$(compgen -A function -X "$module_name._*" "$module_name.")
        if [[ -z "$options" ]]; then
            logger.error "No subcommands available for $module_name"
            return 1
        else
            echo "Available options for $module_name:"
            echo "$options"
        fi
    fi
}

function modules.register_import_path() {
    __import_paths+=("$@")
}

clobber=true modules._create_module_helper logger
clobber=true modules._create_module_helper modules
