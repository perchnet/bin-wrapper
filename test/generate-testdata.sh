#!/usr/bin/env bash
set -euxo pipefail

# test script

TESTSCRIPT=$(
cat <<'EOF'
#!/usr/bin/env bash
echo "\$0 = $0"
for a in "$@"; do
    printf "%q\n" "${a}"
done
EOF
)

if [ -f "$1" ] ; then
    echo "$1 exists!"
    exit 1
fi

mkdir "${1}"

cd "${1}"
mkdir empty_dir
printf %s "${TESTSCRIPT}" > executable
chmod 755 executable
touch executable_empty_file
chmod 755 executable_empty_file
mkdir not_empty_dir
printf %s "${TESTSCRIPT}" > not_executable
chmod 644 not_executable
touch not_executable_empty_file
chmod 644 not_executable_empty_file
touch not_empty_dir/file
ln -s executable link
chmod 755 link
