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

function colors.usage() {
    printf 'Colors usage:
    colors.color NAME
    color names:
        * black
        * blue
        * green
        * cyan
        * red
        * purple
        * brown
        * gray
    colors.bold_color NAME
    bold_color names:
        * gray
        * blue
        * green
        * cyan
        * red
        * purple
        * yellow
        * white
'
}
