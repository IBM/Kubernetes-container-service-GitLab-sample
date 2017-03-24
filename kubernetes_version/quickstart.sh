kubectl create -f postgres.yaml
sleep 15s
kubectl create -f redis.yaml
sleep 15s
kubectl create -f gitlab.yaml
kubectl get nodes
kubectl get svc gitlab