#!/bin/bash -e

test_failed(){
    echo -e >&2 "\033[0;31mdocker-compose test failed!\033[0m"
    exit 1
}

test_passed(){
    echo -e "\033[0;32mdocker-compose test passed!\033[0m"
}

main(){
    if ! docker-compose up -d; then
        test_failed
    elif ! docker-compose ps; then
        test_failed
    elif ! nc -z -v localhost 30080; then
        test_failed
    else
        test_passed
    fi
}

main "$@"
