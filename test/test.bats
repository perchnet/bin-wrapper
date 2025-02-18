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

msg() {
    local from
    from="msg"
    if [[ "$#" -gt 1 ]]; then
        from="${1}"
        shift
    fi
    echo "${from}: $*" 1>&3
}


print_args() {
    local a
    BASH_ARGV0="${real}"
    #!/usr/bin/env bash
    echo "\$0 = $0"
    for a in "$@"; do
        printf "%q\n" "${a}"
    done
}


quoteRe() {
    INPUT="${1}"
    # shellcheck disable=SC1003 # for the regex
    SUBSTITUTED=$(sed -e 's/[^^]/[&]/g' \
    -e 's/\^/\\^/g' \
    -e '$!a\'$'\n''\\n' <<<"${INPUT}" )
    printf %s "${SUBSTITUTED}" | tr -d '\n';
}

@test "test quoteRe()" {
    msg "TODO" "write tests for quoteRe()"
}

splat_flags_to_array() {
    local FLAGS
    ARR=()
    FLAGS=("${@}")
    for FLAG in "${FLAGS[@]}"; do
        ARR+=("${FLAG}")
    done
    printf "%q" "${ARR[@]}"
}

# @test "test splat_flags_to_array" {
#     flags=("-flag1" "-flag$\n2" "-flag 3")
#     arr=("$(splat_flags_to_array "${FLAGS[@]}")")
#     assert_equal "${arr[0]}" "-flag1"
#     assert_equal "${arr[1]}" "-flag$\n2"
#     assert_equal "${arr[2]}" "-flag 3"
# }

splat_flags_to_string() {
    local flag
    while [[ $# -gt 1 ]]; do # while there are more than one arguments
        flag="${1}"
        shift
        printf "%q " "${flag}" # print the flag with a space
    done
    if [[ $# -eq 1 ]]; then # if there is one argument left
        printf "%q" "${1}" # print it
    else # if there are no arguments
        return
    fi
}

@test "test splat_flags_to_string" {
    flags=("-flag1" "-flag
2" "-flag 3")
    str="$(splat_flags_to_string "${flags[@]}")"
    assert_equal "${str}" "-flag1 $'-flag\n2' -flag\ 3"
    #assert_equal "$(splat_flags_to_string "${flags[1]}" "${flags[2]}")" "-flag1 -flag\$\\n2"
}

splat_flags_to_line_delineated_string() {
    local flag
    while [[ $# -gt 1 ]]; do # while there are more than one arguments
        flag="${1}"
        shift
        printf "%q\n" "${flag}" # print the flag with a space
    done
    if [[ $# -eq 1 ]]; then # if there is one argument left
        printf "%q" "${1}" # print it
    else # if there are no arguments
        return
    fi
}

@test "test splat_flags_to_line_delineated_string" {
    flags=("-flag1" "-flag
2" "-flag 3")
    str="$(splat_flags_to_line_delineated_string "${flags[@]}")"
    assert_equal "${str}" "-flag1
$'-flag\n2'
-flag\ 3"
    #assert_equal "$(splat_flags_to_string "${flags[1]}" "${flags[2]}")" "-flag1 -flag\$\\n2"
}

RUNCMD() {
    run wrap_bin "${@}"
}

# generic_test target [flags...]
generic_test() {
    local target wrapper_flags wrapper_flags_splat test_flags regex
    target="${1}"
    shift # remove the target from the arguments
    wrapper_flags=("$@") # the rest of the arguments, if they exist

    real="$(readlink -f "${target:?}")"

    if [[ ! -L ${target} ]]; then # if it's not a link, then
        real="${target}.real" # it will be renamed to target.real
    else
        # it should be a link, triple-check that
        assert_link_exists "${target}"
    fi

    # generate wrapper
    RUNCMD "${target}" "${wrapper_flags[@]}"
    assert_success # it should succeed
    assert_file_executable "${target}" # the target should still be executable

    if [[ "${#wrapper_flags[@]}" == 0 ]]; then
        wrapper_flags_splat=""
        regex="exec ${real}  \"\$@\"" # the regex to match the exec line
    else
        wrapper_flags_splat="$(splat_flags_to_string "${wrapper_flags[@]}")"
        regex="exec ${real} ${wrapper_flags_splat} \"\$@\"" # the regex to match the exec line
    fi
    msg "regex: ${regex}"
    regex="$(quoteRe "${regex}")" # the regex to match the exec line
    # msg "quoted regex: ${regex}"
    cat "${target}"
    assert_file_contains "${target}" "${regex}" # the wrapper should contain the exec line
    test_flags=("flag1" "flag
2" "flag 3")

    combined_flags=("${wrapper_flags[@]}" "${test_flags[@]}")

    # test the wrapper
    run "${target}" "${test_flags[@]}"
    successful_output="$(print_args "${combined_flags[@]}")"
    assert_success
    assert_output "${successful_output}"
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
    fail failing
}

@test "wrap-bin.sh ${DIR}/testdata/link '-flag with spaces'" {
    generic_test "${DIR}/testdata/link" '-flag with spaces'
}
