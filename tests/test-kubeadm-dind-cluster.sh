#!/bin/bash -e

# shellcheck disable=SC1090
source "$(dirname "$0")"/../scripts/resources.sh

setup_dind-cluster() {
    wget https://cdn.rawgit.com/Mirantis/kubeadm-dind-cluster/master/fixed/dind-cluster-v1.7.sh
    chmod 0755 dind-cluster-v1.7.sh
    ./dind-cluster-v1.7.sh up
    export PATH="$HOME/.kubeadm-dind-cluster:$PATH"
}

kubectl_deploy() {
    echo "Running scripts/quickstart.sh"
    "$(dirname "$0")"/../scripts/quickstart.sh

    echo "Waiting for pods to be running"
    i=0
    while [[ $(kubectl get pods | grep -c Running) -ne 3 ]]; do
        if [[ ! "$i" -lt 24 ]]; then
            echo "Timeout waiting on pods to be ready"
            test_failed "$0"
        fi
        sleep 10
        echo "...$i * 10 seconds elapsed..."
        ((i++))
    done
    echo "All pods are running"
}

verify_deploy(){
    echo "Verifying deployment was successful"
    if ! sleep 1 && curl -sS "$(kubectl get svc gitlab | grep gitlab | awk '{ print $2 }')":30080; then
        test_failed "$0"
    fi
}

main(){
    if ! setup_dind-cluster; then
        test_failed "$0"
    elif ! kubectl_deploy; then
        test_failed "$0"
    elif ! verify_deploy; then
        test_failed "$0"
    else
        test_passed "$0"
    fi
}

main
