#!/usr/bin/env bash
# Above ^^ will test that bash is installed

apk add bats

/usr/local/tests/run_tests.sh
