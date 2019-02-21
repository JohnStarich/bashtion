#!/usr/bin/env bash
# Import is an easy way to include other modules.

function import() {
    local output rc
    namespace output "$@"
    rc=$?
    eval "$output"
    return $rc
}
