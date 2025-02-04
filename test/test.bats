
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-file/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    DIR="$(realpath "${DIR}")"
    # make executables in src/ visible to PATH
    PATH="$DIR/../src:$PATH"
    # reset testdata
    rm -fr "${DIR}/testdata"
    >/dev/null 2>&1 "${DIR}/generate-testdata.sh" "${DIR}/testdata"
}
setup

get_usage() {
    wrap-bin.sh --help 2>&1 | grep "Usage:"
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

@test "wrap-bin.sh ${DIR}/testdata/executable (no flags)" {
    run wrap_bin "${DIR}/testdata/executable"
    assert_success
    assert_file_executable "${DIR}/testdata/executable"
    assert_file_contains "${DIR}/testdata/executable" \
        "exec ${DIR}"'/testdata/executable.real  "$@"'
}

@test "wrap-bin.sh ${DIR}/testdata/link (no flags)" {
    assert_link_exists "${DIR}/testdata/link"
    run wrap_bin "${DIR}/testdata/link"
    assert_success
    assert_file_contains "${DIR}/testdata/link" \
        "exec ${DIR}"'/testdata/executable  "$@"'
}

@test "wrap-bin.sh ${DIR}/testdata/executable -flag (simple flag)" {
    run wrap_bin "${DIR}/testdata/executable" -flag
    assert_success
    assert_file_executable "${DIR}/testdata/executable"
    assert_file_contains "${DIR}/testdata/executable" \
        "exec ${DIR}"'/testdata/executable.real -flag  "$@"'
}

@test "wrap-bin.sh ${DIR}/testdata/link -flag (simple flag)" {
    run wrap_bin "${DIR}/testdata/link" -flag
    assert_success
    assert_file_executable "${DIR}/testdata/link"
    assert_file_contains "${DIR}/testdata/link" \
        "exec ${DIR}"'/testdata/executable -flag  "$@"'
}

@test "wrap-bin.sh ${DIR}/testdata/executable '-flag with spaces'" {
    run wrap_bin "${DIR}/testdata/executable" '-flag with spaces'
    assert_success
    assert_file_executable "${DIR}/testdata/executable"
    assert_file_contains "${DIR}/testdata/executable" \
        "exec ${DIR}"'/testdata/executable.real -flag\\ with\\ spaces  "$@"'
}

@test "wrap-bin.sh ${DIR}/testdata/link '-flag with spaces'" {
    run wrap_bin "${DIR}/testdata/link" '-flag with spaces'
    assert_success
    assert_file_executable "${DIR}/testdata/link"
    assert_file_contains "${DIR}/testdata/link" \
        "exec ${DIR}"'/testdata/executable -flag\\ with\\ spaces  "$@"'
}
