#!/usr/bin/env bash

alias retry=retrier.retry
function retrier.retry() {
    if [[ $# == 0 ]]; then
        retrier.usage
        return 2
    fi
    local retry_count=$1
    if [[ "$retry_count" =~ ^-?[0-9]+$ ]]; then
        if (( retry_count < 1 )); then
            logger.error 'Cannot use retry with count less than 1'
            retrier.usage
            return 2
        fi
        shift
    else
        retry_count=3
    fi
    # Mark read-only to prevent retried line from changing it
    declare -r retry_count

    if [[ $# == 0 ]]; then
        retrier.usage
        return 2
    fi

    local rc
    for (( trial = 1; trial == 1 || trial <= retry_count + 1; trial += 1 )); do
        if "$@"; then
            return 0
        else
            rc=$?
            logger.info "Trial $trial exited [$rc]."
            if (( trial != retry_count + 1 )); then
                 logger.info "Retrying... $*"
            fi
        fi
    done
    return $rc
}

function retrier.usage() {
    logger.error "Usage: retry [COUNT] COMMAND [ARGS]"
}
