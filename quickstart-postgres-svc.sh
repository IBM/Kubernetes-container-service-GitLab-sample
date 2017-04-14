#!/bin/bash
kubectl create -f local-volumes.yaml
kubectl create -f redis.yaml
sleep 5s
kubectl create -f gitlab-postgres-svc.yaml
kubectl get nodes
kubectl get svc gitlab
