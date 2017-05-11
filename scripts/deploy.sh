#!/bin/bash

echo "Create Gitlab"
IP_ADDR=$(bx cs workers $CLUSTER_NAME | grep Ready | awk '{ print $2 }')
if [ -z $IP_ADDR ]; then
  echo "$CLUSTER_NAME not created or workers not ready"
  exit 1
fi

echo -e "Configuring vars"
exp=$(bx cs cluster-config $CLUSTER_NAME | grep export)
if [ $? -ne 0 ]; then
  echo "Cluster $CLUSTER_NAME not created or not ready."
  exit 1
fi
eval "$exp"

echo -e "Deleting previous version of Gitlab if it exists"
kubectl delete --ignore-not-found=true svc,pvc,deployment -l app=gitlab
kubectl delete --ignore-not-found=true -f kubernetes/local-volumes.yaml

kuber=$(kubectl get pods -l app=gitlab)
if [ ${#kuber} -ne 0 ]; then
	sleep 30s
fi

echo -e "Creating pods"
kubectl create -f kubernetes/local-volumes.yaml
kubectl create -f kubernetes/postgres.yaml
sleep 5s
kubectl create -f kubernetes/redis.yaml
sleep 5s
kubectl create -f kubernetes/gitlab.yaml
kubectl get nodes
kubectl get svc gitlab

echo "" && echo "View your Gitlab website at http://$IP_ADDR:30080"
