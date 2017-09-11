#!/bin/bash -e

test_failed(){
    echo -e >&2 "\033[0;31mKubernetes test failed!\033[0m"
    exit 1
}

test_passed(){
    echo -e "\033[0;32mKubernetes test passed!\033[0m"
    exit 0
}

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
            test_failed
        fi
        sleep 10
        echo "...$i * 10 seconds elapsed..."
        ((i++))
    done
    echo "All pods are running"
}

verify_deploy(){
    if ! sleep 1 && curl -sS "$(kubectl get svc gitlab | grep gitlab | awk '{ print $2 }')":30080; then
        test_failed
    fi
}

main(){
    if ! setup_dind-cluster; then
        test_failed
    elif ! kubectl_deploy; then
        test_failed
    elif ! verify_deploy; then
        test_failed
    else
        test_passed
    fi
}

main
