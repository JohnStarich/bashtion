#!/usr/bin/env bash
# shellcheck disable=SC2154

import lib/utils/colors


declare -Aig total_exceptions
declare -Aig total_failures
declare -Aig total_skips
declare -Aig total_successes
declare -g test_name

function start() {
    cleanup
    if [[ $# == 0 ]]; then
        logger fatal 'Usage: start TEST_NAME'
        return 2
    fi
    test_name=$1
    total_exceptions["$test_name"]=0
    total_failures["$test_name"]=0
    total_skips["$test_name"]=0
    total_successes["$test_name"]=0
}

function cleanup() {
    set -eu +x
    logger level "$LOG_LEVEL"
}

function success() {
    total_successes["$test_name"]+=1
}

function fail() {
    total_failures["$test_name"]+=1
}

function skip() {
    total_skips["$test_name"]+=1
}

alias abort='abort; return 1'
function abort() {
    total_exceptions["$test_name"]+=1
    logger error 'Test aborted.'
    exception trace
}

function failed() {
    [[ "${total_failures["$test_name"]}" != 0 ]]
}

function stats() {
    cleanup
    declare -i failures=0 successes=0 skips=0 exceptions=0
    for test_failures in "${total_failures[@]}"; do
        failures+="$test_failures"
    done
    for test_successes in "${total_successes[@]}"; do
        successes+="$test_successes"
    done
    for test_skips in "${skips[@]}"; do
        skips+="$test_skips"
    done
    for test_exceptions in "${total_exceptions[@]}"; do
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
            color=${colors_colors[green]}
        else
            color=${colors_colors[red]}
        fi
    fi
    local failed_total=$((total - successes))
    if [[ "$failed_total" == 1 ]]; then
        failed_total+=' test'
    else
        failed_total+=' tests'
    fi
    logger info "${color}${successes}/${total} (${success_rate}%) tests passed. ${failed_total} failed.${colors_colors[reset]}"
    if [[ "$successes" == "$total" ]]; then
        local color=''
        if [[ -t 1 ]]; then
            color=${colors_colors[green]}
        fi
        logger info "${color}All tests passed.${colors_colors[reset]}"
    fi
}

function require_no_failures() {
    declare -i failures=0
    for test_failures in "${total_failures[@]}"; do
        failures+="$test_failures"
    done
    for test_exceptions in "${total_exceptions[@]}"; do
        failures+="$test_exceptions"
    done
    exit $failures
}
