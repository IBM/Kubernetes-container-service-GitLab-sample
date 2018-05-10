[![Build Status](https://travis-ci.org/IBM/Kubernetes-container-service-GitLab-sample.svg?branch=master)](https://travis-ci.org/IBM/Kubernetes-container-service-GitLab-sample)

# GitLab deployment on Kubernetes Cluster

*Read this in other languages: [한국어](README.ko.md)、[中国](README-cn.md) .*

This project shows how a common multi-component workload, in this case GitLab, can be deployed on Kubernetes Cluster. GitLab is famous for its Git-based and code-tracking tool. GitLab represents a typical multi-tier app and each component will have their own container(s). The microservice containers will be for the web tier, the state/job database with Redis and PostgreSQL as the database.

By using different GitLab components (NGINX, Ruby on Rails, Redis, PostgreSQL, and more), you can deploy it to Kubernetes. This example is also deployable using Compose for PostgreSQL in Bluemix as the database.

![Flow](images/gitlab_container_2.png)

1. The user interacts with GitLab via the web interface or by pushing code to a GitHub repository. The GitLab container runs the main Ruby on Rails application behind NGINX and gitlab-workhorse, which is a reverse proxy for large HTTP requests like file downloads and Git push/pull. While serving repositories over HTTP/HTTPS, GitLab utilizes the GitLab API to resolve authorization and access and serves Git objects.

2. After authentication and authorization, the GitLab Rails application puts the incoming jobs, job information, and metadata on the Redis job queue that acts as a non-persistent database.

3. Repositories are created in a local file system.

4. The user creates users, roles, merge requests, groups, and more—all are then stored in PostgreSQL.

5. The user accesses the repository by going through the Git shell.

## Included Components
- [GitLab](https://about.gitlab.com/)
- [PostgreSQL](https://www.postgresql.org/)
- [Redis](https://redis.io/)
- [Kubernetes Clusters](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov)
- [Bluemix container service](https://console.ng.bluemix.net/catalog/?taxonomyNavigation=apps&category=containers)
- [Bluemix Compose for PostgreSQL](https://console.ng.bluemix.net/catalog/services/compose-for-postgresql)

## Objectives
This scenario provides instructions and learning for the following tasks:

- Build containers, and store them in container registry
- Use Kubernetes to create local persistent volumes to define persistent disks
- Deploy containers using Kubernetes pods and services
- Use Bluemix service in Kubernetes applications
- Deploy a distributed GitLab on Kubernetes

## Deployment Scenarios

### Deploy using Docker

see [Deploying Gitlab with Docker](docs/deploy-with-docker.md)

### Deploy to Kubernetes

Use [Deploying Gitlab to IBM Cloud Private](docs/deploy-with-ICP.md) if you wish to install this on IBM Cloud Private, otherwise follow the instructions below.

Create a Kubernetes cluster with either [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube) for local testing, or with [IBM Bluemix Container Service](https://github.com/IBM/container-journey-template#container-journey-template---creating-a-kubernetes-cluster) to deploy in cloud. The code here is regularly tested against [Kubernetes Cluster from Bluemix Container Service](https://console.ng.bluemix.net/docs/containers/cs_ov.html#cs_ov) using Travis.

If you want to use the Bluemix Container Registry start by [Uploading the images](docs/use-bluemix-container-registry.md) to the Bluemix Container Registry.

### Deploy using DevOps Toolchain to Kubernetes Cluster from Bluemix Container Service
If you want to deploy the Gitlab directly to Bluemix, click on `Deploy to Bluemix` button below to create a [Bluemix DevOps service toolchain and pipeline](https://console.ng.bluemix.net/docs/services/ContinuousDelivery/toolchains_about.html#toolchains_about) for deploying the Gitlab sample, else jump to [Steps](#steps)

[![Create Toolchain](https://github.com/IBM/container-journey-template/blob/master/images/button.png)](https://console.ng.bluemix.net/devops/setup/deploy/)

Please follow the [Toolchain instructions](https://github.com/IBM/container-journey-template/blob/master/Toolchain_Instructions_new.md) to complete your toolchain and pipeline.

#### Steps

1. [Use Kubernetes to create Services and Deployments](#1-use-kubernetes-to-create-services-and-deployments-for-gitlab-redis-and-postgresql)
  - 1.1 [Use PostgreSQL in container](#11-use-postgresql-in-container) or
  - 1.2 [Use PostgreSQL from Bluemix](#12-use-postgresql-from-bluemix)
2. [Retrieve external ip and port for GitLab](#2-retrieve-external-ip-and-port-for-gitlab)
3. [GitLab is ready! Use GitLab to host your repositories](#3-gitlab-is-ready-use-gitlab-to-host-your-repositories)

#### 1. Use Kubernetes to create Services and Deployments for GitLab, Redis, and PostgreSQL

Ensure your kubernetes cluster is reachable by running the `kubectl` command.  

```bash
$ kubectl get nodes
NAME             STATUS    AGE       VERSION
x.x.x.x          Ready     17h       v1.5.3-2+be7137fd3ad68f
```

> Note: If this step fails see troubleshooting docs at [Minikube](https://kubernetes.io/docs/getting-started-guides/minikube) or [IBM Bluemix Container Service](https://console.ng.bluemix.net/docs/containers/cs_troubleshoot.html#cs_troubleshoot).

##### 1.1 Use PostgreSQL in container

If you are using a container image to run PostgreSQL, run the following commands or run the quickstart script `./scripts/quickstart.sh` with your Kubernetes cluster.

```bash
$ kubectl create -f kubernetes/local-volumes.yaml
$ kubectl create -f kubernetes/postgres.yaml
$ kubectl create -f kubernetes/redis.yaml
$ kubectl create -f kubernetes/gitlab.yaml
```

After you have created all the services and deployments, wait for 3 to 5 minutes. You can check the status of your deployment on Kubernetes UI. Run `kubectl proxy` and go to URL 'http://127.0.0.1:8001/ui' to check when the GitLab container becomes ready.

![Kubernetes Status Page](images/kube_ui.png)

Next [retrieve your external ip and port for GitLab](#2-retrieve-external-ip-and-port-for-GitLab)

##### 1.2 Use PostgreSQL from Bluemix

Use the Bluemix catalog or the `bx` command to create a service instance of Compose for PostgreSQL and add a set of credentials.

```bash
$ bx service create compose-for-postgresql Standard "Compose for PostgreSQL-GL"
$ bx service key-create "Compose for PostgreSQL-GL" Credentials-1
```

Retrieve the connection string from the credentials object for the service on Bluemix.

```bash
$ bx service key-show "Compose for PostgreSQL-GL" "Credentials-1" | grep "postgres:"
```

![Postgres Connection String example](images/pg_credentials.png)

Modify your ```kubernetes/gitlab-postgres-svc.yaml``` file and replace `COMPOSE_PG_PASSWORD` with the password, `COMPOSE_PG_HOST` with the hostname, and `COMPOSE_PG_PORT` with the port. 

Using the above example, the ```env:``` section will look like this.

```yaml
  env:
  - name: GITLAB_OMNIBUS_CONFIG
  value: |
      postgresql['enable'] = false
      gitlab_rails['db_username'] = "admin"
      gitlab_rails['db_password'] = "ETIDRKCGOEIGBMZA"
      gitlab_rails['db_host'] = "bluemix-sandbox-dal-9-portal.6.dblayer.com"
      gitlab_rails['db_port'] = "26576"
      gitlab_rails['db_database'] = "compose"
      gitlab_rails['db_adapter'] = 'postgresql'
      gitlab_rails['db_encoding'] = 'utf8'
      redis['enable'] = false
      gitlab_rails['redis_host'] = 'redis'
      gitlab_rails['redis_port'] = '6379'
      gitlab_rails['gitlab_shell_ssh_port'] = 30022
      external_url 'http://gitlab.example.com:30080'

```


Run the following commands or run the quickstart script `./scripts/quickstart-postgres-svc.sh` with your Kubernetes cluster.

```bash
$ kubectl create -f kubernetes/local-volumes.yaml
$ kubectl create -f kubernetes/redis.yaml
$ kubectl create -f kubernetes/gitlab-postgres-svc.yaml
```

After you have created all the services and deployments, wait for 3 to 5 minutes. You can check the status of your deployment on Kubernetes UI. Run `kubectl proxy` and go to URL 'http://127.0.0.1:8001/ui' to check when the GitLab container becomes ready.

![Kubernetes Status Page](images/kube_ui_gr.png)

### 2. Retrieve external ip and port for GitLab

After few minutes run the following commands to get your public IP and NodePort number.

```bash
$ $ bx cs workers <cluster_name>
OK
ID                                                 Public IP       Private IP     Machine Type   State    Status   
kube-hou02-pa817264f1244245d38c4de72fffd527ca-w1   169.47.241.22   10.10.10.148   free           normal   Ready 
$ kubectl get svc gitlab
NAME      CLUSTER-IP     EXTERNAL-IP   PORT(S)                     AGE
gitlab    10.10.10.148   <nodes>       80:30080/TCP,22:30022/TCP   2s
```

> Note: The `30080` port is for gitlab UI and the `30022` port is for ssh.

> Note: The gitlab external url is set to `gitlab.example.com` add this to your hosts file pointing to your IP address from above in order to use the url that gitlab expects. If you can't do this, then using the IP (in this example `169.47.241.22`) should work.

> Note: If you using Minikube for local kubernetes deployment, you can access the list of service IPs using the `minikube service list` command.

Congratulations. Now you can use the link [http://gitlab.example.com:30080](http://gitlab.example.com:30080) or http://<node_ip>:30080 to access your gitlab service from your web browser.

### 3. GitLab is ready! Use GitLab to host your repositories

Now that Gitlab is running you can [register as a new user and create a project](docs/using-gitlab.md).

### Troubleshooting

If a pod doesn't start examine the logs.
```bash
kubectl get pods
kubectl logs <pod name>
```

### Cleanup

To delete all your services, deployments, and persistent volume claim, run

```bash
kubectl delete deployment,service,pvc -l app=gitlab
```

To delete your persistent volume, run

```bash
kubectl delete pv local-volume-1 local-volume-2 local-volume-3
```

To delete your PostgreSQL credentials and remove the service instance from Bluemix, run

```bash
bx service key-delete "Compose for PostgreSQL-GL" Credentials-1
bx service delete "Compose for PostgreSQL-GL"
```

# License
[Apache 2.0](LICENSE)

