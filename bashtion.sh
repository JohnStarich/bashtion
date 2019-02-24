#!/usr/bin/env bash
# Bootstrap Bashtion

# Prevent shellcheck rules from being global
true

# Temporarily disable some checks to fail gracefully when invoking the wrong shell.
# shellcheck disable=SC2015,SC2128
[ -n "$BASH_VERSINFO" ] && [ "${BASH_VERSINFO[0]}" -lt 4 ] && echo "This library requires Bash 4 or higher" && exit 1 || true

if [[ "${BASHTION_BOOTSTRAPPED:-}" == true ]]; then
    logger warn 'Already bootstrapped. Skipping...'
    return 0
fi

# Set shell options for running in a production environment.
# We strongly recommend you use these options.
# Only disable if this is NOT running in production.
# To test interactively, use a login shell (i.e. `bash -l`)
if [[ "${UNSAFE:-}" != thisisnotproduction ]]; then
    if ! shopt -q login_shell; then
        # Exit if any command returns a non-zero code.
        set -e
    fi
    # Fail a pipe command if any of the commands fail.
    set -o pipefail
    # Allow aliases for more advanced behavior.
    shopt -s expand_aliases
fi

BASHTION_CACHE=${BASHTION_CACHE:-~/.cache/bashtion}
mkdir -p "$BASHTION_CACHE"

# Ensure goenable is downloaded and enabled
GOENABLE_VERSION=${GOENABLE_VERSION:-0.2.0}
if [[ ! -f "${BASHTION_CACHE}"/goenable.so ]]; then
    curl -fsSL -o "${BASHTION_CACHE}/goenable-${GOENABLE_VERSION}.so" "https://github.com/JohnStarich/goenable/releases/download/${GOENABLE_VERSION}/goenable-$(uname -s)-$(uname -m).so"
fi
enable -f "${BASHTION_CACHE}/goenable-${GOENABLE_VERSION}.so" goenable

if [[ -z "$BASHTION" ]]; then
    # By default, find an existing install of Bashtion and download one if none are found.
    BASHTION_VERSION=${BASHTION_VERSION:-default}
    if [[ "${BASHTION_VERSION}" == default || "${BASHTION_VERSION}" == latest-installed ]]; then
        # attempt to find the highest version installed
        semver=(0 0 0)
        for f in "${BASHTION_CACHE}"/bashtion-*; do
            if [[ "$f" =~ bashtion-([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
                if (( BASH_REMATCH[1] > semver[0] || BASH_REMATCH[2] > semver[1] || BASH_REMATCH[3] > semver[2] )); then
                    semver=("${BASH_REMATCH[@]:1}")
                fi
            fi
        done
        if (( semver[0] != 0 || semver[1] != 0 || semver[2] != 0 )); then
            BASHTION_VERSION="${semver[0]}.${semver[1]}.${semver[2]}"
            BASHTION=${BASHTION_CACHE}/bashtion-${BASHTION_VERSION}
        fi
        unset semver
    fi
    if [[ "${BASHTION_VERSION}" == default && -z "$BASHTION" ]] \
        || [[ "${BASHTION_VERSION}" == latest ]]; then
        BASHTION_VERSION=$(curl -fsSL -H 'Accept: application/vnd.github.v3+json' https://api.github.com/repos/JohnStarich/bashtion/releases/latest)
        BASHTION_VERSION="${BASHTION_VERSION//*tag_name\": \"}"
        BASHTION_VERSION="${BASHTION_VERSION//\"*}"
        BASHTION=${BASHTION_CACHE}/bashtion-${BASHTION_VERSION}
        curl -fsSL -o "$BASHTION" "https://github.com/JohnStarich/bashtion/releases/download/${BASHTION_VERSION}/bashtion-$(uname -s)-$(uname -m)"
    fi
    if [[ ! "$BASHTION_VERSION" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]; then
        echo 'Error determining Bashtion version'
        return 1
    fi
    declare -gr BASHTION_VERSION
fi

if [[ ! -f "$BASHTION" ]]; then
    echo "Error: \$BASHTION is not a file: $BASHTION"
    exit 2
fi

goenable load "$BASHTION" output
eval "${output}"
unset output

import() {
    local output rc opts=${-//c}
    set +ex
    bashtion run namespace output "$@"
    rc=$?
    eval "$output"
    set -"$opts"
    return $rc
}

logger() {
    bashtion run logger "$@"
}

declare -gr BASHTION_BOOTSTRAPPED=true
logger debug 'Fortification complete.'
