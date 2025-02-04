TEMPDIR := `mktemp -du`
REPO := "."

_list:
    just --list

clone_test:
    git clone "{{REPO}}" "{{TEMPDIR}}"
    cd "{{TEMPDIR}}"
    just init-submodules
    just run-tests
    cd -
    rm -fR "{{TEMPDIR}}"
init-submodules:
    git submodule update --init


run-tests:
    ./test/bats/bin/bats test/test.bats