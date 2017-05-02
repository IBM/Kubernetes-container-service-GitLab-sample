#!/bin/bash

function bluemix_auth() {
	echo "Authenticating with Bluemix"
	bx login -a https://api.ng.bluemix.net -u "$BX_USER" -p "$BX_PASS" -c 6aae3a1eef7c0d9f0d6ae1e69e949b2a > /dev/null
	yes | bx plugin install container-registry -r bluemix
	bx cr login
	bx cs init
}


function kubectl_config() {
	echo "Installing and configuring kubectl"
	KUBECONFIG=$(bx cs cluster-config k8stest | awk  -F = '{print $2}' | tr -d '[:space:]')
	export KUBECONFIG
}


function run_tests() {
	echo "Running tests"
	source ./quickstart.sh
	sleep 20

	RUNNING=$(kubectl get pods | grep -c Running)
	if [ $RUNNING -ne 3 ]; then
		exit_tests 1
	fi;

	sleep 60
	IP=$(kubectl get nodes | awk 'NR>1 {print $1}')
	curl -f http://$IP:30080 -o /dev/null || exit_tests 1


	exit_tests 0
}

function exit_tests() {
	kubectl delete pv local-volume-1 local-volume-2 local-volume-3
	kubectl delete deployment,service,pvc -l app=gitlab
	exit $1
}


bluemix_auth
kubectl_config
run_tests
