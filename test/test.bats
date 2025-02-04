
setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/../src:$PATH"

    # reset testdata
    rm -fr "${DIR}/testdata"
    "${DIR}/generate-testdata.sh" "${DIR}/testdata"
}

get_usage() {
    wrap-bin.sh 2>&1 | grep "Usage:"
}
@test "get usage message" {
    run get_usage
    assert_output --partial 'Usage:'
}
