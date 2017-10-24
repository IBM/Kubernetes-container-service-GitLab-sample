#!/bin/bash -e

# shellcheck disable=SC1090
source "$(dirname "$0")"/../scripts/resources.sh

main(){
    if ! docker-compose up -d; then
        test_failed "$0"
    elif ! docker-compose ps; then
        test_failed "$0"
    elif ! sleep 1 && curl -sS localhost:30080; then
        test_failed "$0"
    else
        test_passed "$0"
    fi
}

main "$@"
