#!/usr/bin/env bash
set -euo pipefail
# wrap-bin.sh - Create wrapper script
#
# This script will create a wrapper script, replacing the passed argument (a link) with a wrapper script that applies some flags.

### USAGE ###
USAGE="
Usage: ${0} <link-or-bin> [flag-to-inject [flag-to-inject...]]
Examples:
  - ${0} /usr/bin/firefox --private-window
  - ${0} /usr/bin/firefox --private-window --new-tab https://example.com
  - ${0} /usr/bin/google-chrome --enable-features=UseOzonePlatform,TouchpadOverscrollHistoryNavigation --ozone-platform=wayland

If <link-or-bin> is a link, it will be replaced with a script that launches the target with the flags passed.

If <link-or-bin> is a binary, the binary will be renamed to <binary>.real and a script will be created in its place. The script will launch the binary with the flags passed.

If <link-or-bin> is not an absolute path, it will be resolved from the PATH.
"
#######################
set -x

### FUNCTIONS ###
# Splat passed flags to an escaped string
SPLAT_FLAGS() {
    local FLAGS_SPLAT
    if [[ -n "${1:-}" ]]; then
        FLAGS_SPLAT="$(printf "%q " "${@}")"
    else
        FLAGS_SPLAT=""
    fi
    printf %s "${FLAGS_SPLAT}"
}

# Return a template of the script, with the target and flags substituted, and the script's name in the header.
TEMPLATE_SCRIPT() {
    local SCRIPT
    SCRIPT='#!/bin/bash
# __SCRIPT__
exec __TARGET__ __FLAGS__ "$@" '
    SCRIPT="${SCRIPT//__SCRIPT__/"${LINK_OR_BIN}"}" # Replace the comment in the header, so we can identify the script
    SCRIPT="${SCRIPT//__TARGET__/"${TARGET}"}" # Substitute the target in
    #SCRIPT="${SCRIPT//__FLAGS__/"$(SPLAT_FLAGS "${FLAGS[@]}")"}" # Substitute the flags in
    SCRIPT="${SCRIPT//__FLAGS__/"${SPLAT_FLAGS}"}" # Substitute the flags in
    printf "%s\n" "${SCRIPT}"
}

MAIN() {
    # Check if the user passed an argument, display USAGE and fail if not
    LINK_OR_BIN="${1:?"${USAGE}"}"
    [[ "${LINK_OR_BIN}" == "--help" ]] && echo "${USAGE}" && return 0

    # If LINK_OR_BIN is not an absolute path, resolve it from $PATH
    if [[ ! "${LINK_OR_BIN}" == /* ]]; then
        LINK_OR_BIN=$(command -v "${LINK_OR_BIN}")
    fi

    # Get flags from command line
    #shift # Remove LINK_OR_BIN from the arguments
    FLAGS=("${@:2}") # Set the remaining arguments as flags
    SPLAT_FLAGS="$(SPLAT_FLAGS "${FLAGS[@]}")"


    # `test -x FOO_FILE` returns true for executable files, but also returns true for executable links that point to executables. However, it returns false for broken links, regular files, and nonexistant files.
    RETURN_IF_NOT_X="${RETURN_IF_NOT_X:-0}" # Set to 1 to fail
    if [[ ! -x "${LINK_OR_BIN}" ]] ; then
        echo "${LINK_OR_BIN} is not an executable, skipping..."
        return "${RETURN_IF_NOT_X}"
    fi

    # Check the target
    TARGET=$(readlink -e "${LINK_OR_BIN}")
    if [[ -L "${LINK_OR_BIN}" ]] ; then
        # LINK_OR_BIN is a link, so we can just remove it to replace it with a wrapper script that calls it.
        rm -f "${LINK_OR_BIN}"
    else
        # LINK_OR_BIN is not a link, so we can't just replace it with a script. Rename to ${TARGET}.real and our wrapper will call that.
        TARGET="${TARGET}.real"
        mv "${LINK_OR_BIN}" "${TARGET}"
    fi

    # Now template the script into the destination.
    TEMPLATE_SCRIPT > "${LINK_OR_BIN}"
    chmod +x "${LINK_OR_BIN}"
}

MAIN "${@}"
