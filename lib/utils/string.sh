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
