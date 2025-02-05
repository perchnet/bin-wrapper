# shellcheck shell=bash
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-file/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    # shellcheck disable=SC2154
    DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" >/dev/null 2>&1 && pwd)"
    DIR="$(realpath "${DIR}")"
    # make executables in src/ visible to PATH
    PATH="${DIR}/../src:${PATH}"
    # reset testdata
    rm -fr "${DIR}/testdata"
    "${DIR}/generate-testdata.sh" >/dev/null 2>&1 "${DIR}/testdata"
}
setup

# https://stackoverflow.com/a/29613573
#   quoteRe <text>
# shellcheck disable=SC1003
quoteRe() {
    INPUT="${1}"
    SUBSTITUTED=$(sed -e 's/[^^]/[&]/g' \
    -e 's/\^/\\^/g' \
    -e '$!a\'$'\n''\\n' <<<"${INPUT}" )
    printf %s "${SUBSTITUTED}" | tr -d '\n';
}

get_usage() {
    OUTPUT=$(wrap-bin.sh --help 2>&1)
    grep "Usage:" <<<"${OUTPUT}"
}
@test "get usage message" {
    run get_usage
    assert_output --partial 'Usage:'
}

wrap_bin() {
    wrap-bin.sh "$@"
}

@test "wrap-bin.sh with no arguments" {
    run wrap_bin
    assert_failure
    assert_output --partial 'Usage:'
}

# generic test
generic_test() {
    local TARGET FLAGS FLAGS_SPLAT REAL regex
    TARGET="${1}"
    shift
    if [[ -n "$*" ]] ; then
        # no extra flags
        FLAGS_SPLAT=""
    else
        # extra flags
        FLAGS_SPLAT="$(printf %q "$@")"
    fi
    REAL="$(readlink -f "${TARGET:?}")"
    if [[ "${TARGET}" == "${REAL}" ]]; then
        # it will be renamed to TARGET.real
        REAL="${TARGET}.real"
    else
        # it should be a link, triple-check that
        assert_link_exists "${TARGET}"
    fi
    run wrap_bin "${TARGET}" "${FLAGS[@]}"
    assert_success
    assert_file_executable "${TARGET}"
    regex="$(quoteRe 'exec '"${REAL}" "${FLAGS_SPLAT}"' "$@"')"
    assert_file_contains "${TARGET}" \
        "${regex}"
    run "${TARGET}"
    assert_success
    cat "${TARGET}"
    OUTPUT="\$0 = ${REAL}"
    run "${TARGET}"
    assert_output "${OUTPUT}"
    run "${TARGET}" "arg1" "arg2" "arg with spaces"
    assert_success
    OUTPUT="\$0 = ${REAL}"
    assert_output "${OUTPUT}
arg1
arg2
arg\ with\ spaces"
}
@test "wrap-bin.sh ${DIR}/testdata/executable (no flags)" {
    generic_test "${DIR}/testdata/executable"
}

@test "wrap-bin.sh ${DIR}/testdata/link (no flags)" {
    generic_test "${DIR}/testdata/link"
}

@test "wrap-bin.sh ${DIR}/testdata/executable -flag (simple flag)" {
    generic_test "${DIR}/testdata/executable" -flag
}

@test "wrap-bin.sh ${DIR}/testdata/link -flag (simple flag)" {
    generic_test "${DIR}/testdata/link" -flag
}

@test "wrap-bin.sh ${DIR}/testdata/executable '-flag with spaces'" {
    generic_test "${DIR}/testdata/executable" '-flag with spaces'
}

@test "wrap-bin.sh ${DIR}/testdata/link '-flag with spaces'" {
    generic_test "${DIR}/testdata/link" '-flag with spaces'
}
