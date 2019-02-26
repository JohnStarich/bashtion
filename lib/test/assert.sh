#!/usr/bin/env bash
# shellcheck disable=SC2154

import lib/test/test
import lib/utils/colors
import lib/utils/exception
import lib/utils/string


function init() {
    shopt -s extglob
}

function true() {
    if [[ $# == 0 ]]; then
        logger fatal "Usage: true COMMAND [ARGS ...]"
        exception trace
        test abort
        return 2
    fi
    local rc=0
    eval "$@" || rc=$?
    if [[ $rc != 0 ]]; then
        _log_failure "Return code is non-zero ($rc)"
        logger error "Failed command: $*"
        exception trace
        test fail
        return 1
    else
        test success
    fi
}

function false() {
    if [[ $# == 0 ]]; then
        logger fatal "Usage: false COMMAND [ARGS ...]"
        exception trace
        test abort
        return 2
    fi
    local rc=0
    eval "$@" || rc=$?
    if [[ $rc == 0 ]]; then
        _log_failure "Return code is zero"
        logger error "Failed command: $*"
        exception trace
        test fail
        return 1
    else
        test success
    fi
}

function equal() {
    if [[ $# != 2 ]]; then
        logger fatal "Usage: equal EXPECTED ACTUAL"
        exception trace
        test abort
        return 2
    fi
    local expected=$1
    local actual=$2
    if [[ "$expected" != "$actual" ]]; then
        _log_failure "$actual is not equal to $expected"
        logger error "Expected: $expected"
        logger error "Actual:   $actual"
        exception trace
        test fail
        return 1
    else
        test success
    fi
}

function not_equal() {
    if [[ $# != 2 ]]; then
        logger fatal "Usage: equal UNEXPECTED ACTUAL"
        exception trace
        test abort
        return 2
    fi
    local unexpected=$1
    local actual=$2
    if [[ "$unexpected" == "$actual" ]]; then
        _log_failure "$actual is equal to $unexpected"
        logger error "Unexpected value: $actual"
        exception trace
        test fail
        return 1
    else
        test success
    fi
}

function contains() {
    if [[ $# != 2 ]]; then
        logger fatal "Usage: contains STRING SUBSTRING"
        exception trace
        test abort
        return 2
    fi
    local haystack=$1
    local needle=$2
    if [[ "$haystack" != *"$needle"* ]]; then
        _log_failure "String does not contain '$needle'"
        logger error "Substring: $needle"
        logger error "String: $haystack"
        exception trace
        test fail
        return 1
    else
        test success
    fi
}

function not_contains() {
    if [[ $# != 2 ]]; then
        logger fatal "Usage: not_contains STRING SUBSTRING"
        exception trace
        test abort
        return 2
    fi
    local haystack=$1
    local needle=$2
    if [[ "$haystack" == *"$needle"* ]]; then
        _log_failure "String contains '$needle'"
        logger error "Substring: $needle"
        logger error "String: $haystack"
        exception trace
        test fail
        return 1
    else
        test success
    fi
}

function _progress_line() {
    local total=$((__successes + __failures + __exceptions))
    local success_rate
    if [[ "$total" == 0 ]]; then
        success_rate=100
    else
        success_rate=$((100 * __successes / total))
    fi
    local color=''
    if [[ -t 1 ]]; then
        if [[ "$success_rate" == 100 ]]; then
            color=${colors_colors[green]}
        else
            color=${colors_colors[red]}
        fi
    fi
    local failed_total=$((total - __successes))
    if [[ "$failed_total" == 1 ]]; then
        failed_total+=' test'
    else
        failed_total+=' tests'
    fi
    logger info "${color}${__successes}/${total} (${success_rate}%) tests passed. ${failed_total} failed.${colors_colors[reset]}"
}

function stats() {
    logger info "Test Results:"
    local total=$((__successes + __failures + __exceptions))
    _progress_line
    if [[ "$__successes" == "$total" ]]; then
        local color=''
        if [[ -t 1 ]]; then
            color=${colors_colors[green]}
        fi
        logger info "${color}All tests passed.${colors_colors[reset]}"
    fi
}

function _log_failure() {
    printf '\n'
    logger error "${FUNCNAME[1]} failed: $*"
}

# requires shopt -s extglob
# regex source: https://stackoverflow.com/a/54766117/1530494
function strip-color() {
    declare -n var=$1
    var=${var//$'\e'[\[(]*([0-9;])[@-n]/}
}
