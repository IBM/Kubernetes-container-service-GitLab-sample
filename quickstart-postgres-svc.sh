#!/bin/bash
kubectl create -f kubernetes/local-volumes.yaml
kubectl create -f kubernetes/redis.yaml
kubectl create -f kubernetes/gitlab-postgres-svc.yaml
kubectl get nodes
kubectl get svc gitlab
