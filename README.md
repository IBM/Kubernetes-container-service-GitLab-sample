kubectl create -f gitlab-ns.yml

kubectl create -f kubernetes/local-volumes.yaml

kubectl create -f kubernetes/postgres.yaml

kubectl create -f kubernetes/redis.yaml

kubectl create -f kubernetes/gitlab.yaml







Uteis:

kubectl exec gitlab-546c5cfb66-2qlxt -i -t -- bash -il
