#!/bin/bash

# Unfortunately, in terraform, external programs need to output json,
# so can't use `git rev-parse` directly in terraform. This
# shell script converts output to json

# We use SHORT_HASH var set in google cloud builds, because they don't have
# a real git repo

if [[ ! -z $SHORT_HASH ]]; then
  printf "{\"SHORT_HASH\": \"$SHORT_HASH\"}"
  exit 0
fi

printf "{\"SHORT_HASH\": \"`git rev-parse --verify --short HEAD`\"}"
