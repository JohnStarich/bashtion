#!/usr/bin/env bash

import utils/colors


declare -Arg __trace_colors=(
    [default]="${colors[reset]}"
    [arrow]="$(colors.bold_rgb 255 0 0)"
    [source]="$(colors.bold)"
    [function]="$(colors.rgb 32 179 142)"
    [line_number]="$(colors.rgb 94 44 242)"
)

function exception._trace_frame() {
    declare -i frame=$1
    local src=$2 func=$3 line=$4
    if [[ -t 1 ]]; then
        printf '%s' "${__trace_colors[default]}"
        string.pad $((frame * 2))
        printf '%s' "${__trace_colors[arrow]}» "
        printf '%s' "${__trace_colors[default]}"
        printf '%s' "${__trace_colors[source]}${src}"
        printf '%s' "${__trace_colors[default]}:"
        printf '%s' "${__trace_colors[line_number]}${line}"
        printf '%s' "${__trace_colors[default]} "
        printf '%s' "${__trace_colors[function]} ${func}${__trace_colors[default]}() "
        printf '%s\n' "${colors[reset]}"
    else
        string.pad $((frame * 2))
        printf -- '-> %s:%d %s()\n' "$src" "$line" "$func"
    fi
}

function exception.trace() {
    declare -i frame=1
    while [[ -n "${BASH_SOURCE[$frame + 1]:-}" ]]; do
        exception._trace_frame "$((frame - 1))" "${BASH_SOURCE[$frame + 1]}" "${FUNCNAME[$frame]}" "${BASH_LINENO[$frame]}"
        frame+=1
    done
}
