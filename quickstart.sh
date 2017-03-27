#!/bin/bash
kubectl create -f local-volumes.yaml
kubectl create -f postgres.yaml
sleep 5s
kubectl create -f redis.yaml
sleep 5s
kubectl create -f gitlab.yaml
kubectl get nodes
kubectl get svc gitlab