#!/bin/bash

echo "Create Gitlab"
IP_ADDR=$(bx cs workers "$CLUSTER_NAME" | grep Ready | awk '{ print $2 }')
if [[ -z "$IP_ADDR" ]]; then
  echo "$CLUSTER_NAME not created or workers not ready"
  exit 1
fi

echo -e "Configuring vars"
if ! exp=$(bx cs cluster-config "$CLUSTER_NAME" | grep export); then
  echo "Cluster $CLUSTER_NAME not created or not ready."
  exit 1
fi
eval "$exp"

echo -e "Deleting previous version of Gitlab if it exists"
kubectl delete --ignore-not-found=true svc,pvc,deployment -l app=gitlab
kubectl delete --ignore-not-found=true -f kubernetes/local-volumes.yaml

echo -e "Creating pods"
kubectl create -f kubernetes/local-volumes.yaml
kubectl create -f kubernetes/postgres.yaml
kubectl create -f kubernetes/redis.yaml
kubectl create -f kubernetes/gitlab.yaml
kubectl get svc gitlab

echo "" && echo "View your Gitlab website at http://$IP_ADDR:30080"

echo "Note: Your Gitlab may take up to 5 minutes to be fully functioning"
