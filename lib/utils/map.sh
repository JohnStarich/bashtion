#!/usr/bin/env bash
# Map is a convenient wrapper for Bash associative arrays.
# Currently this module is mainly for internal use. It needs some love before seeing major use.

function map._is_invalid_map_var() {
    local map_var=$1
    if declare -p "$map_var" &>/dev/null; then
        return 1
    fi
    logger.error "'$map_var' is not an existing variable"
    return 0
}

function map._contains_indirect() {
    local map_var=$1
    # Key is used in the eval statement
    # shellcheck disable=SC2034
    local key=$2
    eval "[[ -n \"\${${map_var}[\"\$key\"]+x}\" ]]"
}

function map._set_indirect() {
    local map_var=$1
    local key=$2
    local value=$3
    {
        # Indirect assignment requires $ on left hand side
        # shellcheck disable=SC1066
        eval "${map_var}[\"\$key\"]=\"\$value\""
    } || {
        logger.fatal "Error setting '$key'='$value' for map $map_var"
        exception.trace
        return 2
    }
}

function map.keys() {
    if [[ $# != 1 ]]; then
        logger.error 'Usage: map.keys MAP_VAR'
        return 2
    fi
    local map_var=$1
    if map._is_invalid_map_var "$map_var"; then
        return 2
    fi
    eval "
    for key in \"\${!${map_var}[@]}\"; do
        printf '%s\\n' \"\$key\"
    done
    "
}

function map.read_set() {
    if [[ $# != 1 ]]; then
        logger.error 'Usage: map.read_set MAP_VAR'
        return 2
    fi
    local map_var=$1
    if map._is_invalid_map_var "$map_var"; then
        return 2
    fi
    local line
    while read -r line; do
        map._set_indirect "$map_var" "$line" ''
    done
}

function map.diff_keys() {
    if [[ $# != 3 ]]; then
        logger.error 'Usage: map.diff_keys MAP_A MAP_B RESULT'
    fi
    local map_a=$1
    local map_b=$2
    local result=$3
    if map._is_invalid_map_var "$map_a" || map._is_invalid_map_var "$map_b" || map._is_invalid_map_var "$result"; then
        return 2
    fi

    declare -a map_a_keys
    readarray -t map_a_keys <<<"$(map.keys "$map_a")"
    for key in "${map_a_keys[@]}"; do
        if ! map._contains_indirect "$map_b" "$key"; then
            map._set_indirect "$result" "$key" ''
        fi
    done

    declare -a map_b_keys
    readarray -t map_b_keys <<<"$(map.keys "$map_b")"
    for key in "${map_b_keys[@]}"; do
        if ! map._contains_indirect "$map_a" "$key"; then
            map._set_indirect "$result" "$key" ''
        fi
    done
}
