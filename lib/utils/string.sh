#!/usr/bin/env bash
# String utilities written entirely in Bash.

function string.basename() {
    if [[ "$*" =~ ([^/]+)/*$|(/)/*$ ]]; then
        printf '%s\n' "${BASH_REMATCH[1]:-${BASH_REMATCH[2]}}"
    elif [[ -n "$*" ]]; then
        return 2
    fi
}

function string.dirname() {
    local path=$*
    if [[ "$path" =~ /*[^/]*/*$ ]]; then
        local sans_base="${path%"${BASH_REMATCH[0]}"}"
        if [[ -n "$sans_base" ]]; then
            printf '%s\n' "$sans_base"
        else
            if [[ "${path:0:1}" == / ]]; then
                printf '/\n'
            else
                printf '.\n'
            fi
        fi
    else
        return 2
    fi
}

function string.pad() {
    declare -i pad_size=$1
    printf "%${pad_size}s" ''
}

function string.nth_token() {
    declare -i token_index=$1; shift
    # Intentionally not quoting to make use of splits based on IFS
    # shellcheck disable=SC2206
    declare -a tokens=($*)
    if ((token_index < -${#tokens} || token_index >= ${#tokens})); then
        logger.error "Index out of bounds: (${tokens[*]}) at index $token_index"
        return 2
    fi
    printf '%s\n' "${tokens[token_index]}"
}
