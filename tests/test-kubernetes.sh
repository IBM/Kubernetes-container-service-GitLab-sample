#!/bin/bash

kubeclt_clean() {
    echo "Cleaning cluster"
    kubectl delete pv local-volume-1 local-volume-2 local-volume-3
    kubectl delete deployment,service,pvc,replicaset -l app=gitlab
}

test_failed(){
    kubeclt_clean
    echo -e >&2 "\033[0;31mKubernetes test failed!\033[0m"
    exit 1
}

test_passed(){
    kubeclt_clean
    echo -e "\033[0;32mKubernetes test passed!\033[0m"
    exit 0
}

kubectl_config() {
    echo "Configuring kubectl"
    #shellcheck disable=SC2091
    $(bx cs cluster-config "$CLUSTER_NAME" | grep export)
}


kubectl_deploy() {
    kubeclt_clean

    echo "Running scripts/quickstart.sh"
    "$(dirname "$0")"/../scripts/quickstart.sh

    echo "Waiting for pods to be running"
    i=0
    while [[ $(kubectl get pods | grep -c Running) -ne 3 ]]; do
        if [[ ! "$i" -lt 24 ]]; then
            echo "Timeout waiting on pods to be ready"
            test_failed
        fi
        sleep 10
        echo "...$i * 10 seconds elapsed..."
        ((i++))
    done
    echo "All pods are running"

    echo "Waiting for service to be available"
    sleep 120
}

verify_deploy(){
    IPS=$(bx cs workers "$CLUSTER_NAME" | awk '{ print $2 }' | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
    for IP in $IPS; do
        if ! curl -sS "$IP":30080; then
            test_failed
        fi
        echo
    done
}

main(){
    if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
        echo -e "\033[0;33mPull Request detected; not running Kubernetes test.\033[0m"
        exit 0
    fi

    if ! kubectl_config; then
        echo "Config failed."
        test_failed
    elif ! kubectl_deploy; then
        echo "Deploy failed"
        test_failed
    elif ! verify_deploy; then
        test_failed
    else
        test_passed
    fi
}

main
