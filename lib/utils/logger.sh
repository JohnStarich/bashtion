#!/usr/bin/env bash
# Logger enables more advanced message handling, including colorization and
# log levels.

declare -Arg __levels=(
    [ALL]=0
    [TRACE]=1
    [DEBUG]=2
    [INFO]=3
    [WARN]=4
    [ERROR]=5
    [FATAL]=6
    [OFF]=7
)
declare -rg __max_level=${__levels[OFF]}

declare -g __level=${__levels[ALL]}
declare -g __log_file

declare -Arg __level_colors=(
    [default]=$'\e[0m'
    [TRACE]=$'\e[0;35m'
    [DEBUG]=$'\e[0;32m'
    [WARN]=$'\e[1;33m'
    [ERROR]=$'\e[0;31m'
    [FATAL]=$'\e[1;31m'
)

function logger.init() {
    LOG_LEVEL=${LOG_LEVEL:-debug}
    logger.set_level "$LOG_LEVEL"
    LOG_FILE=${LOG_FILE:-/dev/stderr}
    logger.set_file "$LOG_FILE"
}

function logger._redirect_to_log_file() {
    if [[ "$__log_file" == /dev/stderr ]]; then
        exec >&2
    elif [[ "$__log_file" == /dev/stdout ]]; then
        exec >&1
    else
        exec >>"$__log_file"
    fi
}

function logger.add() {
    # Return as early as possible to reduce overhead (and verbosity, if `set -x` is on)
    [[ "${__levels["${1^^}"]:-$__max_level}" < ${__level} ]] && return
    {
        logger._redirect_to_log_file
        local level=${1^^}; shift
        local message=$*
        local level_num
        case "$level" in
            TRACE|DEBUG|INFO|WARN|ERROR|FATAL)
                level_num=${__levels["$level"]}
                ;;
            *)
                logger.fatal "Invalid log level: $level"
                exit 1
                ;;
        esac
        if [[ $level_num < ${__level} ]]; then
            return
        fi

        # Colorize if stdout is a tty
        if [[ -t 1 ]]; then
            local reset_color=${__level_colors[default]}
            local level_color=${__level_colors["$level"]:-$reset_color}
            printf '%s[%s%5s%s] ' "$reset_color" "$level_color" "$level" "$reset_color"
        else
            printf '[%5s] ' "$level"
        fi
        printf '%s\n' "$message"
        if [[ -t 1 ]]; then
            printf '%s' "$reset_color"
        fi
    }
}

alias trace=logger.trace
function logger.trace() {
    logger.add trace "$@"
}

alias debug=logger.debug
function logger.debug() {
    logger.add debug "$@"
}

alias info=logger.info
function logger.info() {
    logger.add info "$@"
}

alias warn=logger.warn
function logger.warn() {
    logger.add warn "$@"
}

alias error=logger.error
function logger.error() {
    logger.add error "$@"
}

alias fatal=logger.fatal
function logger.fatal() {
    logger.add fatal "$@"
}

function logger.level() {
    printf '%s\n' "${__level}"
}

function logger.set_level() {
    if [[ $# != 1 ]]; then
        logger._level_usage
        return 2
    fi
    local level=${1^^}
    if [[ -z "${__levels["$level"]:+x}" ]]; then
        logger._level_usage
        return 2
    fi
    __level=${__levels["$level"]}
}

function logger.set_file() {
    local file=$1
    if [[ -e "$file" && ! -w "$file" ]]; then
        logger.fatal "Could not set logger file. Cannot write to file: '$file'"
        return 2
    elif [[ -d "$file" ]]; then
        logger.fatal "Could not set logger file. File must not be a directory: '$file'"
        return 2
    fi
    __log_file="$file"
}

function logger._level_usage() {
    local level_names=(all debug info warn error fatal off)
    logger.error 'Usage: logger.set_level LEVEL'
    logger.error "Level options: ${level_names[*]}"
}
