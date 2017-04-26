# PLACEHOLDER DOC

# Steps using Compose for PostgreSQL on Bluemix as the database

Note: The Compose for PostgreSQL service on Bluemix is available through a pricing plan. Please see [Compose for PostgreSQL Catalog item](https://console.ng.bluemix.net/catalog/services/compose-for-postgresql/) for more details on pricing.


1. [Install Docker CLI and Bluemix Container registry Plugin](#1-install-docker-cli-and-bluemix-container-registry-plugin)
2. [Create Compose for PostgreSQL on Bluemix](#2-create-compose-for-postgresql-on-bluemix)
3. [Create Services and Deployments](#3-create-services-and-deployments)
4. [Using Gitlab](#4-using-gitlab)

# 1. Install Docker CLI and Bluemix Container Registry Plugin


First, install [Docker CLI](https://www.docker.com/community-edition#/download).

Then, install the Bluemix container registry plugin.

```bash
bx plugin install container-registry -r bluemix
```

Once the plugin is installed you can log into the Bluemix Container Registry.

```bash
bx cr login
```

If this is the first time using the Bluemix Container Registry you must set a namespace which identifies your private Bluemix images registry. It can be between 4 and 30 characters.

```bash
bx cr namespace-add <namespace>
```

Verify that it works.

```bash
bx cr images
```

# 2. Create Compose for PostgreSQL on Bluemix

Use the Bluemix catalog or the bx command to create a service instance of Compose for PostgreSQL and add a set of credentials.

```bash
bx service create compose-for-postgresql Standard "Compose for PostgreSQL-GL"
bx service key-create "Compose for PostgreSQL-GL" Credentials-1
```

Get the name of the target cluster and bind the credentials of the service instance to your kubernetes cluster.

```bash
bx cs clusters
bx cs cluster-service-bind <your cluster name> default "Compose for PostgreSQL-GL"
```

Verify that the credentials have been added.

```bash
kubectl get secrets
```

# 3. Create Services and Deployments

Run the following commands:

```bash
kubectl create -f local-volumes.yaml
kubectl create -f redis.yaml
kubectl create -f gitlab-postgres-svc.yaml
```

After you have created all the services and deployments, wait for 3 to 5 minutes. You can check the status of your deployment on Kubernetes UI. Run 'kubectl proxy' and go to URL 'http://127.0.0.1:8001/ui' to check when the GitLab container becomes ready.

![Kubernetes Status Page](images/kube_ui_gr.png)

After few minutes run the following commands to get your public IP and NodePort number.

```bash
$ kubectl get nodes
NAME             STATUS    AGE
169.47.241.106   Ready     23h
$ kubectl get svc gitlab
NAME      CLUSTER-IP     EXTERNAL-IP   PORT(S)                     AGE
gitlab    10.10.10.148   <nodes>       80:30080/TCP,22:30022/TCP   2s
```

> Note: The 30080 port is for gitlab UI and the 30022 port is for ssh.

Congratulation. Now you can use the link **http://[IP]:30080** to access your gitlab site on browser.

> Note: For the above example, the link would be http://169.47.241.106:30080  since its IP is 169.47.241.106 and the UI port number is 30080.


# 4. Using GitLab

Refer back to [Using Gitlab](README.md#4-using-gitlab)

# Troubleshooting
If a pod doesn't start examine the logs.
```bash
kubectl get pods
kubectl logs <pod name>
```

To delete all your kubernetes services, deployments, and persistent volume claim, run

```bash
kubectl delete deployment,service,pvc -l app=gitlab
```

To delete your persistent volume, run

```bash
kubectl delete pv local-volume-1 local-volume-2 local-volume-3
```

To delete your PostgreSQL secret in kubernetes and remove the service instance from Bluemix, run

```bash
kubectl delete secret binding-compose-for-postgresql-gl
bx service key-delete "Compose for PostgreSQL-GL" Credentials-1
bx service delete "Compose for PostgreSQL-GL"
```

# License
[Apache 2.0](LICENSE)
