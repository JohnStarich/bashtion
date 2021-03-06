#!/usr/bin/env bash

declare -Agr colors=(
    [reset]=$'\e[0m'
    [black]=$'\e[0;30m'
    [blue]=$'\e[0;34m'
    [green]=$'\e[0;32m'
    [cyan]=$'\e[0;36m'
    [red]=$'\e[0;31m'
    [purple]=$'\e[0;35m'
    [brown]=$'\e[0;33m'
    [gray]=$'\e[0;37m'
)

declare -Agr bold_colors=(
    [gray]=$'\e[1;30m'
    [blue]=$'\e[1;34m'
    [green]=$'\e[1;32m'
    [cyan]=$'\e[1;36m'
    [red]=$'\e[1;31m'
    [purple]=$'\e[1;35m'
    [yellow]=$'\e[1;33m'
    [white]=$'\e[1;37m'
)

declare -Agr background_colors=(
    [black]=$'\e[0;40m'
    [red]=$'\e[0;41m'
    [green]=$'\e[0;42m'
    [yellow]=$'\e[0;43m'
    [blue]=$'\e[0;44m'
    [purple]=$'\e[0;45m'
    [cyan]=$'\e[0;46m'
    [white]=$'\e[0;47m'
)

function colors.color() {
    if [[ $# == 0 ]]; then
        logger.error 'No color name provided'
        colors.usage
        return 2
    fi
    local name=$1
    if [[ -n "${colors["$name"]:+x}" ]]; then
        logger.error 'Invalid color name'
        colors.usage
        return 2
    fi
    printf '%s' "${colors["$name"]}"
}

function colors.bold_color() {
    if [[ $# == 0 ]]; then
        logger.error 'No bold_color name provided'
        colors.usage
        return 2
    fi
    local name=$1
    if [[ -n "${bold_colors["$name"]:+x}" ]]; then
        logger.error 'Invalid bold_color name'
        colors.usage
        return 2
    fi
    printf '%s' "${bold_colors["$name"]}"
}

function colors.background_color() {
    if [[ $# == 0 ]]; then
        logger.error 'No background_color name provided'
        colors.usage
        return 2
    fi
    local name=$1
    if [[ -n "${background_colors["$name"]:+x}" ]]; then
        logger.error 'Invalid background_color name'
        colors.usage
        return 2
    fi
    printf '%s' "${background_colors["$name"]}"
}

function colors.bold() {
    printf '\e[1m'
}

function colors._rgb() {
    if [[ $# != 3 ]]; then
        logger.error 'Usage: colors.rgb RED GREEN BLUE'
        logger.error 'Color values must be between 0 and 255'
        return 2
    fi
    declare -i red=$1 green=$2 blue=$3
    if (( red > 255 || red < 0 || green > 255 || green < 0 || blue > 255 || blue < 0 )); then
        logger.error 'Usage: colors.rgb RED GREEN BLUE'
        logger.error 'Color values must be between 0 and 255'
        return 2
    fi
    printf '\e[38;2;%d;%d;%dm' "$red" "$green" "$blue"
}

function colors.rgb() {
    # Reset "brightness" (bold)
    printf '\e[0m'
    colors._rgb "$@"
}

function colors.bold_rgb() {
    # Set "brightness" (bold)
    colors.bold
    colors._rgb "$@"
}

function colors.background_rgb() {
    if [[ $# != 3 ]]; then
        logger.error 'Usage: colors.background_rgb RED GREEN BLUE'
        logger.error 'Color values must be between 0 and 255'
        return 2
    fi
    declare -i red=$1 green=$2 blue=$3
    if (( red > 255 || red < 0 || green > 255 || green < 0 || blue > 255 || blue < 0 )); then
        logger.error 'Usage: colors.background_rgb RED GREEN BLUE'
        logger.error 'Color values must be between 0 and 255'
        return 2
    fi
    printf '\e[48;2;%d;%d;%dm' "$red" "$green" "$blue"
}

function colors.usage() {
    printf 'Colors usage:
    colors.color COLOR_NAME
    colors.bold_color COLOR_NAME
    colors.background_color COLOR_NAME
    colors.bold

    color names:
        * black
        * blue
        * green
        * cyan
        * red
        * purple
        * brown
        * gray
'
}
