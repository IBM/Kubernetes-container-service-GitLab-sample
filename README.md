[![Build Status](https://travis-ci.org/IBM/kubernetes-container-service-gitlab-sample.svg?branch=master)](https://travis-ci.org/IBM/kubernetes-container-service-gitlab-sample)

# Running Gitlab Community Edition in Containers

This project shows how a common multi-component application can be deployed in containers, whether it be locally in Docker, or via a Container scheduler like Bluemix Container Service (Kubernetes).

Click through to [Deployment Scenarios](#deployment-scenarios) to skip straight to deploying Gitlab CE.

Refer back to the [IBM|code](https://developer.ibm.com/code/journey/run-gitlab-kubernetes/) page for more details about this project.

## About Gitlab Community Edition

[GitLab Community Edition](https://about.gitlab.com/) (CE) represents a typical multi-tier app and each component will have their own container(s). In this case we have three containers, a gitlab container which provides the http and git user entrypoints, a PostgreSQL container for the stateful database and a Redis container for the state/job database.

![Flow](images/gitlab_container_2.png)

1. The user interacts with GitLab via the web interface or by pushing code to a GitHub repository. The GitLab container runs the main Ruby on Rails application behind NGINX and gitlab-workhorse, which is a reverse proxy for large HTTP requests like file downloads and Git push/pull. While serving repositories over HTTP/HTTPS, GitLab utilizes the GitLab API to resolve authorization and access and serves Git objects.

2. After authentication and authorization, the GitLab Rails application puts the incoming jobs, job information, and metadata on the Redis job queue that acts as a non-persistent database.

3. Repositories are created in a local file system.

4. The user creates users, roles, merge requests, groups, and more—all are then stored in PostgreSQL.

5. The user accesses the repository by going through the Git shell.

# Deployment Scenarios

## Getting Started

### 1. Install Docker CLI 

First, install [Docker](https://www.docker.com) by following the instructions [here](https://www.docker.com/community-edition#/download) for your preferrerd operating system.

For the following scenarios we will be using the following official images from the Docker Hub: [Gitlab CE](https://store.docker.com/images/gitlab-community-edition?tab=description), [PostgreSQL](https://store.docker.com/images/postgres?tab=description), [Redis](https://store.docker.com/images/redis?tab=description).

## Scenarios

Choose one of the following scenarios that best matches your needs, or if you're just wanting to learn, step through them one at a time and read the supporting documents and configuration files.

1. [Single Container deployment via Docker](#single-container-deployment-via-docker)
2. [Multiple Container deployment via Docker Compose](#multiple-container-deployment-via-docker-compose)
3. [Multiple Container deployment using Bluemix Container Service (kubernetes)](#multiple-container-deployment-using-bluemix-container-service-kubernetes)
4. [Production Ready Deployment using Bluemix Container Service and Compose for PostgreSQL](docs/bluemix-production.md)

## Single Container deployment via Docker

*For more detailed instructions please visit the [Deploy Gitlab CE with Docker](https://developer.ibm.com/code/blog/deploy-gitlab-with-docker) blog post on IBM|Code.*

### Deploy

The easiest, but least versatile way to deploy Gitlab CE is to launch it directly on your laptop which is already running Docker.  By default gitlab includes postgres and redis in the container to make it easy to run as just a single container.

```bash
$ sudo docker run --detach \
    --hostname gitlab.example.com \
    --publish 30080:80 --publish 30022:22 \
    --name gitlab \
    gitlab/gitlab-ce:9.1.0-ce.0

```

### Use

Once gitlab is started you will be able to access it via http://<DOCKER_HOST>:30080. See [Using Gitlab](#using-gitlab)

### Teardown

Once you're done you can stop your container, and then remove it:

```bash
$ sudo docker stop gitlab
$ sudo docker rm gitlab
```

## Multiple Container deployment via Docker Compose

It's easy to connect gitlab to external PostgreSQL and Redis services by making a few tweaks to the environment variables passed to the gitlab container.  In the root of this repo is a [docker-compose.yml](docker-compose.yml) file which will demonstrate a multiple container deployment that you can run locally or against a remote docker server.

*For more detailed iformation including detailed information about the docker compose manifest please visit the [Deploy Gitlab CE with Docker Compose](https://developer.ibm.com/code/blog/deploy-gitlab-with-docker-compose) blog post on IBM|Code.*

### Deploy

```bash
$ docker-compose up -d
Starting kubernetescontainerservicegitlabsample_redis_1
Starting kubernetescontainerservicegitlabsample_postgresql_1
Recreating kubernetescontainerservicegitlabsample_gitlab_1
```

### Use

Once gitlab is started you will be able to access it via http://<DOCKER_HOST>:30080. See [Using Gitlab](#using-gitlab)

### Teardown

Once you're done you can stop your container, and then remove it:

```bash
$ sudo docker-compose stop gitlab
$ sudo docker-compose rm gitlab
```

## Multiple Container deployment using Bluemix Container Service (kubernetes)

In order to perform this deployment scenario you will need to have access to a kubernetes cluster, to make it easier for you we are including instructions on how to enable and use the Bluemix Container Service which has a basic free tier.

*For more detailed instructions please visit the [Deploy Gitlab CE using Kubernetes](https://developer.ibm.com/code/blog/deploy-gitlab-on-kubernetes) blog post on IBM|Code.*

### Bluemix Container Service

_if you already have a kubernetes cluster via [minikube]((https://developer.ibm.com/code/blog/deploy-minikube-on-softlayer) or similar you can skip this step and go straight to [2. Create Services and Deployments](2-create-services-and-deployments)._

#### Create a Bluemix Container Service Kubernetes cluster

Create a Kubernetes cluster with IBM Bluemix Container Service called `gitlab`.

If you have not setup the Kubernetes cluster, now would be a great time to read over the Bluemix documentation and follow the [Containers tutorial](https://console.ng.bluemix.net/docs/containers/cs_tutorials.html#cs_tutorials) to create a Bluemix Container Cluster.

Ensure that your cluster is set up correctly by running:

```bash
$  bx cs clusters
Listing clusters...
OK
Name   ID                                 State    Created                    Workers   
gitlab   3a75579ef4604ad6b6c352aace834114   normal   2017-04-20T18:39:26+0000   1   
```

_Refer back to the [Containers documentation](https://console.ng.bluemix.net/docs/containers) for troubleshooting steps if this step fails._

#### Upload containers to Bluemix Container Registry (optional):

If you want to use the Bluemix Container registry you can copy images directly from the Docker Hub to Bluemix by as shown in [this tutorial](https://console.ng.bluemix.net/docs/containers/container_images_adding_ov.html#container_images_copying).  If you do this you will want to modify the the files in `kubernetes/*.yaml` to point to your own images.  for instance `image: gitlab/gitlab-ce:latest` in `kubernetes/gitlab.yaml` would become `image: registry.ng.bluemix.net/<my_namespace>/gitlab-ce:latest`.

### 2. Create Services and Deployments

Run the following commands to deploy gitlab to kubernetes.

```bash
$ kubectl create -f local-volumes.yaml
$ kubectl create -f postgres.yaml
$ kubectl create -f redis.yaml
$ kubectl create -f gitlab.yaml
```

_Refer to the [Deploy Gitlab CE using Kubernetes](https://developer.ibm.com/code/blog/deploy-gitlab-on-kubernetes) blog post on IBM|Code for a detailed writeup of these kubernetes manifests._

After you have created all the services and deployments, wait for 3 to 5 minutes. You can check the status of your deployment on Kubernetes UI. Run `kubectl proxy` and go to URL [http://127.0.0.1:8001/ui](http://127.0.0.1:8001/ui) to check when the GitLab container becomes ready.

![Kubernetes Status Page](images/kube_ui.png)

After few minutes the following commands to get your public IP and NodePort number.

```bash
$ kubectl get nodes
NAME             STATUS    AGE
169.47.241.106   Ready     23h
```

> Note: For this example the IP address we'll use is `169.47.241.106`

```bash
$ kubectl get svc gitlab
NAME      CLUSTER-IP     EXTERNAL-IP   PORT(S)                     AGE
gitlab    10.10.10.148   <nodes>       80:30080/TCP,22:30022/TCP   2s
```

> Note: The `30080` port is for gitlab UI and the `30022` port is for ssh.

Congratulation. Now you can use the link **http://[IP]:30080** to access your gitlab site on browser.

> Note: For the above example, the link would be http://169.47.241.106:30080  since its IP is 169.47.241.106 and the UI port number is 30080. Proceed to [Using Gitlab](#using-gitlab).

#### Troubleshooting

If a pod doesn't start examine the logs.
```bash
kubectl get pods
kubectl logs <pod name>
```


#### Teardown

To delete all your services, deployments, and persistent volume claim, run

```bash
$ kubectl delete deployment,service,pvc -l app=gitlab
```

To delete your persistent volume, run

```bash
$ kubectl delete pv local-volume-1 local-volume-2 local-volume-3
```

Finally you can delete your Bluemix Container Service kubernetes cluster, run

```bash
$ bx cs cluster-rm test
Remove the cluster? [test] (Y/N)> y
Removing cluster test...
OK
```


### Using GitLab
Now that Gitlab is running you can register as a new user and create a project.

![Registration page](images/register.png)


After logging in as your newly-created user you can create a new project.

![Create project](images/new_project.png)

Once a project has been created you'll be asked to add an SSH key for your user.

To verify that your key is working correctly run:

```bash
ssh -T git@<IP> -p 30022
```

Which should result in:

```bash
Welcome to GitLab, <user>!
```

Now you can clone your project.
```bash
git clone ssh://git@<IP>:30022/<user>/<project name>
```

Add a file and commit:
```bash
echo "Gitlab project" > README.md
git add README.md
git commit -a -m "Initial commit"
git push origin master
```

You can now see it in the Gitlab UI.
![Repo](images/first_commit.png)

If you want to use http URLs for cloning and pushing to a public repository on GitLab, that`s enabled as well.

# License
[Apache 2.0](LICENSE)
