#!/usr/bin/env bash
# Above ^^ will test that bash is installed

apk add bats nodejs

/usr/local/tests/run_tests.sh
