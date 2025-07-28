#!/bin/sh

[ -z "$MD2MS" ] && echo "MD2MS environment variable is not set." && exit 1
[ -z "$MD2MAN" ] && echo "MD2MAN environment variable is not set." && exit 1

TEST_INPUT_DIR="$PWD/test/input"
TEST_OUTPUT_DIR="$PWD/test/output"

test_md2ms() {
    local input_file="$1"
    local output_file="out.tmp"
    local expected_output_file="$2"

    "$MD2MS" "$input_file" > "$output_file"

    if diff -qw "$output_file" "$expected_output_file"; then
        echo "Test passed for $input_file"
    else
        echo "Test failed for $input_file"
        diff "$output_file" "$expected_output_file"
    fi

    rm -f "$output_file"
}

test_md2man() {
    local input_file="$1"
    local output_file="out.tmp"
    local expected_output_file="$2"

    "$MD2MAN" < "$input_file" > "$output_file"

    if diff -qw "$output_file" "$expected_output_file"; then
        echo "Test passed for $input_file"
    else
        echo "Test failed for $input_file"
        diff "$output_file" "$expected_output_file"
    fi

    rm -f "$output_file"
}

for f in "$TEST_INPUT_DIR"/*.md; do
    base_name=$(basename "$f" .md)
    test_md2ms "$f" "$TEST_OUTPUT_DIR/${base_name}.ms"
    test_md2man "$f" "$TEST_OUTPUT_DIR/${base_name}.man"
done
