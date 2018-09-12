kubectl create -f gitlab-ns.yml
kubectl create -f kubernetes/local-volumes.yaml
kubectl create -f kubernetes/postgres.yaml
kubectl create -f kubernetes/redis.yaml
kubectl create -f kubernetes/gitlab.yaml
