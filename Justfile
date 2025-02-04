# Justfile
# Portions taken from https://github.com/m2Giles/m2os/blob/main/Justfile thank you! 💖
PROJECT := "bin-wrapper"
REPO := "."

[private]
default: list

[private]
list:
    @just --list

# Check Just Syntax
[group('Just')]
check:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
        echo "Checking syntax: $file"
        just --unstable --fmt --check -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt --check -f Justfile

# Fix Just Syntax
[group('Just')]
fix:
    #!/usr/bin/env bash
    find . -type f -name "*.just" | while read -r file; do
        echo "Checking syntax: $file"
        just --unstable --fmt -f $file
    done
    echo "Checking syntax: Justfile"
    just --unstable --fmt -f Justfile || { exit 1; }
# Cleanup
[group('Utility')]
clean:
    #!/usr/bin/env bash
    set -euox pipefail
    git clean -fdX

# Initialize submodules
[group('Utility')]
init-submodules:
    git submodule update --init

# Run pre-commit hooks, clone this repo to a temp dir, and run tests
[group('Utility')]
clone-and-test:
    #!/usr/bin/env bash
    set -euxo pipefail
    just pre-commit
    TEMPDIR="$(mktemp --tmpdir -d {{ PROJECT }}.XXXXXXXX)"
    git clone "{{ REPO }}" "${TEMPDIR}" --recursive
    cd "${TEMPDIR}"
    just run-tests
    cd -
    rm -fR "${TEMPDIR}"

# Run bats tests
[group('Tests')]
run-tests:
    #!/usr/bin/env bash
    set -euxo pipefail
    [ ! -d ./test/bats ] && just init-submodules
    ./test/bats/bin/bats test/test.bats

# Run pre-commit hooks
[group('Lint')]
pre-commit:
    pre-commit run -a

# Run pre-commit hooks and tests
[group('Utility')]
lint-test: pre-commit run-tests
