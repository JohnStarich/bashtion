#!/usr/bin/env bash
# shellcheck disable=SC2154

import utils/colors


declare -Aig __exceptions
declare -Aig __failures
declare -Aig __skips
declare -Aig __successes

function test.start() {
    set -eu +x
    logger.set_level "$LOG_LEVEL"

    if [[ $# == 0 ]]; then
        logger.fatal 'Usage: test.start TEST_NAME'
        return 2
    fi
    __test_name=$1
    __exceptions["$__test_name"]=0
    __failures["$__test_name"]=0
    __skips["$__test_name"]=0
    __successes["$__test_name"]=0
}

function test.success() {
    __successes["$__test_name"]+=1
}

function test.fail() {
    __failures["$__test_name"]+=1
}

function test.skip() {
    __skips["$__test_name"]+=1
}

function test.abort() {
    __exceptions["$__test_name"]+=1
    # TODO trigger EXIT
}

function test.failed() {
    [[ "${__failures["$__test_name"]}" != 0 ]]
}

function test.stats() {
    set -eu +x
    declare -i failures=0 successes=0 skips=0 exceptions=0
    for test_failures in "${__failures[@]}"; do
        failures+="$test_failures"
    done
    for test_successes in "${__successes[@]}"; do
        successes+="$test_successes"
    done
    for test_skips in "${__skips[@]}"; do
        skips+="$test_skips"
    done
    for test_exceptions in "${__exceptions[@]}"; do
        exceptions+="$test_exceptions"
    done

    declare -i total=$((failures + successes + skips + exceptions))
    declare -i success_rate=100
    if [[ "$total" != 0 ]]; then
        success_rate=$((100 * successes / total))
    fi

    local color=''
    if [[ -t 1 ]]; then
        if [[ "$success_rate" == 100 ]]; then
            color=${colors[green]}
        else
            color=${colors[red]}
        fi
    fi
    local failed_total=$((total - successes))
    if [[ "$failed_total" == 1 ]]; then
        failed_total+=' test'
    else
        failed_total+=' tests'
    fi
    logger.info "${color}${successes}/${total} (${success_rate}%) tests passed. ${failed_total} failed."
    if [[ "$successes" == "$total" ]]; then
        local color=''
        if [[ -t 1 ]]; then
            color=${colors[green]}
        fi
        logger.info "${color}All tests passed."
    fi
}
