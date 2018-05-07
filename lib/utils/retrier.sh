#!/usr/bin/env bash

alias retry=retrier.retry
function retrier.retry() {
    if [[ $# == 0 ]]; then
        retrier.usage
        return 2
    fi
    local retry_count=$1
    if [[ "$retry_count" =~ ^[0-9]+$ ]]; then
        if (( retry_count == 0 )); then
            logger.error 'Cannot use retry with count of 0'
            retrier.usage
            return 2
        fi
        shift
    else
        retry_count=3
    fi

    if [[ $# == 0 ]]; then
        retrier.usage
        return 2
    fi

    for (( trial = 1; trial == 1 || trial <= retry_count + 1; trial += 1 )); do
        rc=0
        "$@" || rc=$?
        if (( rc == 0 )); then
            break
        elif (( trial != retry_count + 1 )); then
            logger.info "Trial $trial exited [$rc]. Retrying... $*"
        fi
    done
    return $rc
}

function retrier.usage() {
    logger.error "Usage: retry [COUNT] COMMAND [ARGS]"
}
