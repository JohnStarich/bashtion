#!/usr/bin/env bash

import test/assert
import utils/retrier


assert retrier.retry echo hi >/dev/null
assert.equal hello "$(retrier.retry echo hello)"

function bad_exit_code() {
    return 1
}

assert ! retrier.retry bad_exit_code

declare -i fail_counter=1
function succeed_nth_time() {
    local nth_time=$1
    if [[ $nth_time == 0 || $((fail_counter % nth_time)) == 0 ]]; then
        return 0
    fi
    fail_counter+=1
    return 1
}

fail_counter=1
assert retrier.retry succeed_nth_time 0

fail_counter=1
assert retrier.retry succeed_nth_time 1

fail_counter=1
assert.false retrier.retry succeed_nth_time 10

fail_counter=1
assert retrier.retry 10 succeed_nth_time 10

function devious() {
    export rc=0
    return 1
}

assert.false retrier.retry devious

assert.false retrier.retry 0 echo hello >/dev/null
assert.false retrier.retry -1 echo hello >/dev/null
