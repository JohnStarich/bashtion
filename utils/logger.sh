#!/usr/bin/env bash
# Logger enables more advanced message handling, including colorization and
# log levels.

declare -A __levels
__levels=(
    [ALL]=0
    [DEBUG]=1
    [INFO]=2
    [WARN]=3
    [ERROR]=4
    [FATAL]=5
    [OFF]=6
)

__level=${__levels[ALL]}

declare -A __level_colors
__level_colors=(
    [default]=$'\033[0m'
    [DEBUG]=$'\033[0;32m'
    [WARN]=$'\033[1;33m'
    [ERROR]=$'\033[0;31m'
    [FATAL]=$'\033[1;31m'
)

function logger.add() {
    local level=${1^^}; shift
    local message=$*
    local level_num
    case "$level" in
        DEBUG|INFO|WARN|ERROR|FATAL)
            level_num=${__levels[$level]}
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
        local level_color=${__level_colors[$level]:-$reset_color}
        printf '%s[%s%5s%s] ' "$reset_color" "$level_color" "$level" "$reset_color"
    else
        printf '[%5s] ' "$level"
    fi
    printf '%s\n' "$message"
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
