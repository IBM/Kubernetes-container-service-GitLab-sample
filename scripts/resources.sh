#!/bin/bash

# This script contains functions used by many of the scripts found in scripts/
# and tests/.

test_failed(){
    echo -e >&2 "\033[0;31m$1 test failed!\033[0m"
    exit 1
}

test_passed(){
    echo -e "\033[0;32m$1 test passed!\033[0m"
}

is_pull_request(){
  if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
      echo -e "\033[0;33mPull Request detected; not running $1!\033[0m"
      exit 0
  fi
}
