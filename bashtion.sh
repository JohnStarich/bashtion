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

if [[ ! -f "$BASHTION" && ! -L "$BASHTION" ]]; then
    echo "Error: \$BASHTION is not a file: $BASHTION"
    exit 2
fi

goenable load "$BASHTION" output
eval "${output}"
unset output

logger() {
    bashtion run logger "$@"
}

declare -ag __import_stack=()

import() {
    local output rc opts=${-//[cis]}
    set +ex
    __import_stack=("$*" "${__import_stack[@]}")
    bashtion run namespace output "$@"
    rc=$?
    if [[ $rc == 0 && -n "${output:+x}" ]]; then
        # Source the output to provide a usable stack for debugging
        # shellcheck disable=SC1090
        source <(echo "$output")
        rc=$?
    fi
    if (( rc != 0 )); then
        # Use a bit of logic from utils/exception to show the error and a small trace
        logger error "Error during 'import $*'"
        local padding previous_import next_import last_non_import
        for (( frame=0; frame < ${#FUNCNAME[@]}; frame++ )); do
            if [[ "${FUNCNAME[$frame]}" != import && "${BASH_SOURCE[$frame]}" != /dev/fd/* ]]; then
                # TODO don't depend on /dev/fd prefix when skipping intermediate imports
                last_non_import=${BASH_SOURCE[$frame]}
                break
            fi
        done
        declare -i import_frame=0
        for (( frame=0; frame < ${#FUNCNAME[@]}; frame++ )); do
            if [[ "${FUNCNAME[$frame]}" == import ]]; then
                padding=$(printf "%$((import_frame * 2))s" '')
                previous_import=${__import_stack[$import_frame]}
                next_import=${__import_stack[$import_frame + 1]-$last_non_import}
                logger error "${padding}"$'\e[1;31m'"» $next_import:${BASH_LINENO[$frame]}"$'\e[0m'" import $previous_import"
                import_frame+=1
            fi
        done
        exit 2
    fi
    __import_stack=("${__import_stack[@]:1}")
    set -"$opts"
    return $rc
}

declare -gr BASHTION_BOOTSTRAPPED=true
logger debug 'Fortification complete.'
