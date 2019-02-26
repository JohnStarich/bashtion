#!/usr/bin/env bash

import lib/utils/colors
import lib/utils/string


declare -Arg trace_colors=(
    [default]="${colors_colors[reset]}"
    [arrow]="$(colors bold_rgb 255 0 0)"
    [source]="$(colors bold)"
    [function]="$(colors rgb 32 179 142)"
    [line_number]="$(colors rgb 94 44 242)"
)

function init() {
    set -E
    trap 'exception-trace "${BASH_SOURCE[0]}" "${FUNCNAME[0]}" "${LINENO}"' ERR
    # Bash 4 has special behavior for the EXIT trap and resets LINENO to 1
    # Source: https://lists.gnu.org/archive/html/bug-bash/2010-09/msg00035.html
    # For now, just indicate it was triggered by an exit
    trap 'if [[ $? != 0 ]]; then exception-trace "${BASH_SOURCE[0]-unknown}" "${FUNCNAME[0]-unknown}" "(exit)"; fi' EXIT
}

function _trace_frame() {
    {
        exec >&2
        declare -i trace_line=$1
        local src=$2 func=$3 line=$4
        local max_src_length=35
        if [[ "$src" == /* ]] && ((${#src} > max_src_length + 3 )); then
            # Trim absolute paths to a more reasonable length
            src=...${src: -$max_src_length}
        fi
        if [[ -t 1 ]]; then
            printf '%s' "${trace_colors[default]}"
            string pad $((trace_line * 2))
            printf '%s' "${trace_colors[arrow]}» "
            printf '%s' "${trace_colors[default]}"
            printf '%s' "${trace_colors[source]}${src}"
            printf '%s' "${trace_colors[default]}:"
            printf '%s' "${trace_colors[line_number]}${line}"
            printf '%s' "${trace_colors[default]} "
            printf '%s' "${trace_colors[function]} ${func}${trace_colors[default]}() "
            printf '%s\n' "${colors_colors[reset]}"
        else
            string pad $((trace_line * 2))
            printf -- '-> %s:%s %s()\n' "$src" "$line" "$func"
        fi
    }
}

function trace() {
    declare -i trace_line=0
    if [[ $# != 0 ]]; then
        local err_source=$1 err_func=$2 err_lineno=$3
        _trace_frame "$trace_line" "$err_source" "$err_func" "$err_lineno"
        trace_line+=1
    fi
    declare -i frame=1
    while [[ -n "${BASH_SOURCE[$frame + 1]:-}" ]]; do
        _trace_frame "$trace_line" "${BASH_SOURCE[$frame + 1]}" "${FUNCNAME[$frame]}" "${BASH_LINENO[$frame]}"
        frame+=1
        trace_line+=1
    done
}
