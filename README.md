# GitLab deployment on Bluemix Kubernetes Container Service

## Overview
This project shows how a common multi-component application can be deployed
on the Bluemix container service with Kubernetes clusters. Each component runs in a separate container
or group of containers. 

Gitlab represents a typical multi-tier app and each component will have their own container(s). The microservice containers will be for the web tier, the state/job database with Redis and PostgreSQL as the database.


![Flow](images/gitlab_container.png)

## Included Components
- Bluemix container service
- Kubernetes
- GitLab
- NGINX
- Redis
- PostgreSQL

## Prerequisite

Create a Kubernetes cluster with IBM Bluemix Container Service. 

If you have not setup the Kubernetes cluster, please follow the [Creating a Kubernetes cluster](https://github.com/IBM/container-journey-template) tutorial.

## QuickStart

For QuickStart, please go to [step 3](#3-create-services-and-deployments). We will use the images from DockerHub for QuickStart. If you want to build your private images, please follow the detailed [steps](#steps).


## Steps

1. [Install Docker CLI and Bluemix Container registry Plugin](#1-install-docker-cli-and-bluemix-container-registry-plugin)
2. [Build PostgreSQL and Gitlab containers](#2-build-postgresql-and-gitlab-containers)
3. [Create Services and Deployments](#3-create-services-and-deployments)
4. [Using Gitlab](#4-using-gitlab)

# 1. Install Docker CLI and Bluemix Container Registry Plugin

> Note: If you do not want to build your private images for gitlab, please skip to [Create Services and Deployments](#3-create-services-and-deployments).

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


# 2. Build PostgreSQL and Gitlab containers

Build the PostgreSQL container.

```bash
cd containers/postgres
docker build -f registry.ng.bluemix.net/<namespace>/gitlab-postgres .
docker push registry.ng.bluemix.net/<namespace>/gitlab-postgres
```

Build the Gitlab container.

```bash
cd containers/gitlab
docker build -f registry.ng.bluemix.net/<namespace>/gitlab .
docker push registry.ng.bluemix.net/<namespace>/gitlab
```


After finish building the images in bluemix registery, please modify the container images in your yaml files. 

i.e. 
1. In postgres.yaml, change `docker.io/tomcli/postgres:latest` to `registry.ng.bluemix.net/<namespace>/gitlab-postgres`
2. In gitlab.yaml, change `docker.io/tomcli/gitlab:latest` to `registry.ng.bluemix.net/<namespace>/gitlab`

> Note: Replace `<namespace>` to your own container registry namespace. You can check your namespace via `bx cr namespaces`

# 3. Create Services and Deployments

Run the following commands or run the quickstart script `bash quickstart.sh` with your Kubernetes cluster.

```bash
kubectl create -f postgres.yaml
kubectl create -f redis.yaml
kubectl create -f gitlab.yaml
```
After you created all the services and deployments, wait for 3 to 5 minutes and run the following commands to get your public IP and NodePort number.

```bash
$ kubectl get nodes
NAME             STATUS    AGE
169.47.241.106   Ready     23h
$ kubectl get svc gitlab
NAME      CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
gitlab    10.10.10.90   <nodes>       80:30911/TCP   16h
```

Congratulation. Now you can use the link **http://[IP]:[port number]** to access your gitlab site.

> Note: For the above example, the link would be http://169.47.241.106:30911  since its IP is 169.47.241.106 and its port number is 30911. 


# 4. Using Gitlab
Now that Gitlab is running you can register as a new user and create a project.

![Registration page](images/register.png)


After logging in as your newly-created user you can create a new project.

![Create project](images/new_project.png)

Once a project has been created you'll be asked to add an SSH key for your user.

To verify that your key is working correctly run:

```bash
ssh -T git@<IP>
```

Which should result in:

```bash
Welcome to GitLab, <user>!
```

Now you can clone your project.
```bash
git clone <project URL>
```

Add a file and commit:
```bash
echo "Gitlab project" > README.md
git add README.md
git commit -a -m "Initial commit"
```

You can now see it in the Gitlab UI.
![Repo](images/first_commit.png)

# Troubleshooting
If a pod doesn't start examine the logs.
```bash
kubectl get pods
kubectl logs <pod name>
```


To delete all your services and deployments, run

```bash
kubectl delete deployment,service -l app=gitlab
```

# License
[Apache 2.0](LICENSE.txt)
