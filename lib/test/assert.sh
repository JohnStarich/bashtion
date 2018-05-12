#!/usr/bin/env bash
# shellcheck disable=SC2154

import utils/colors

declare -ig __exceptions=0
declare -ig __failures=0
declare -ig __successes=0

alias assert=assert.true
function assert.true() {
    if [[ $# == 0 ]]; then
        logger.fatal "Usage: assert.true COMMAND [ARGS ...]"
        assert._log_trace
        __exceptions+=1
        return 2
    fi
    local rc=0
    eval "$@" || rc=$?
    if [[ $rc != 0 ]]; then
        assert._log_failure "Return code is non-zero ($rc)"
        logger.error "$*"
        assert._log_trace
        __failures+=1
        return 1
    else
        __successes+=1
    fi
}

function assert.false() {
    if [[ $# == 0 ]]; then
        logger.fatal "Usage: assert.false COMMAND [ARGS ...]"
        assert._log_trace
        __exceptions+=1
        return 2
    fi
    local rc=0
    eval "$@" || rc=$?
    if [[ $rc == 0 ]]; then
        assert._log_failure "Return code is zero"
        logger.error "$*"
        assert._log_trace
        __failures+=1
        return 1
    else
        __successes+=1
    fi
}

function assert.equal() {
    if [[ $# != 2 ]]; then
        logger.fatal "Usage: assert.equal EXPECTED ACTUAL"
        assert._log_trace
        __exceptions+=1
        return 2
    fi
    local expected=$1
    local actual=$2
    if [[ "$expected" != "$actual" ]]; then
        assert._log_failure "$actual is not equal to $expected"
        logger.error "Expected: $expected"
        logger.error "Actual:   $actual"
        assert._log_trace
        __failures+=1
        return 1
    else
        __successes+=1
    fi
}

function assert.not_equal() {
    if [[ $# != 2 ]]; then
        logger.fatal "Usage: assert.equal UNEXPECTED ACTUAL"
        assert._log_trace
        __exceptions+=1
        return 2
    fi
    local unexpected=$1
    local actual=$2
    if [[ "$unexpected" == "$actual" ]]; then
        assert._log_failure "$actual is equal to $unexpected"
        logger.error "Unexpected value: $actual"
        assert._log_trace
        __failures+=1
        return 1
    else
        __successes+=1
    fi
}

function assert._progress_line() {
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
            color=${colors[green]}
        else
            color=${colors[red]}
        fi
    fi
    local failed_total=$((total - __successes))
    if [[ "$failed_total" == 1 ]]; then
        failed_total+=' test'
    else
        failed_total+=' tests'
    fi
    logger.info "${color}${__successes}/${total} (${success_rate}%) tests passed. ${failed_total} failed."
}

function assert.stats() {
    logger.info "Test Results:"
    local total=$((__successes + __failures + __exceptions))
    assert._progress_line
    if [[ "$__successes" == "$total" ]]; then
        local color=''
        if [[ -t 1 ]]; then
            color=${colors[green]}
        fi
        logger.info "${color}All tests passed."
    fi
}

function assert._log_failure() {
    printf '\n'
    logger.error "${FUNCNAME[1]} failed: $*"
}

function assert._log_trace() {
    logger.error "-> $(caller 1)"
}

function assert._reset() {
    __successes=0
    __failures=0
    __exceptions=0
}
