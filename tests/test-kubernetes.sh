#!/bin/bash

# This script is intended to be run by Travis CI. If running elsewhere, invoke
# it with: TRAVIS_PULL_REQUEST=false [path to script]

# shellcheck disable=SC1090
source "$(dirname "$0")"/../scripts/resources.sh

kubeclt_clean() {
    echo "Cleaning cluster"
    kubectl delete pvc,deployment,service,replicaset -l app=gitlab
    sleep 30s
    kubectl delete pv local-volume-1 local-volume-2 local-volume-3
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
    while [[ $(kubectl get pods -l app=gitlab | grep -c Running) -ne 3 ]]; do
        if [[ ! "$i" -lt 24 ]]; then
            echo "Timeout waiting on pods to be ready"
            kubectl get pods -a
            test_failed "$0"
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
    echo "Verifying deployment was successful"
    IPS=$(bx cs workers "$CLUSTER_NAME" | awk '{ print $2 }' | grep '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}')
    for IP in $IPS; do
        if ! curl -sS "$IP":30080; then
            test_failed "$0"
        fi
        echo
    done
}

main(){
    is_pull_request "$0"

    if ! kubectl_config; then
        echo "Config failed."
        test_failed "$0"
    elif ! kubectl_deploy; then
        echo "Deploy failed"
        test_failed "$0"
    elif ! verify_deploy; then
        test_failed "$0"
    else
        test_passed "$0"
    fi
}

main
