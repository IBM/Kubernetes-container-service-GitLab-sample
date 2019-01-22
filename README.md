[![Build Status](https://travis-ci.org/IBM/Kubernetes-container-service-GitLab-sample.svg?branch=master)](https://travis-ci.org/IBM/Kubernetes-container-service-GitLab-sample)

# GitLab deployment on Kubernetes Cluster

*Read this in other languages: [한국어](README.ko.md)、[中国](README-cn.md) .*

This project shows how a common multi-component workload, in this case GitLab, can be deployed on Kubernetes Cluster. GitLab is famous for its Git-based and code-tracking tool. GitLab represents a typical multi-tier app and each component will have their own container(s). The microservice containers will be for the web tier, the state/job database with Redis and PostgreSQL as the database.

By using different GitLab components (NGINX, Ruby on Rails, Redis, PostgreSQL, and more), you can deploy it to Kubernetes. This example is also deployable using [Databases for PostgreSQL in IBM Cloud as the database](docs/bluemix-postgres.md).

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
- [Minio](https://github.com/minio/minio)
- [Kubernetes Clusters](https://cloud.ibm.com/docs/containers/cs_ov.html#cs_ov)
- [IBM Cloud Kubernetes Service](https://cloud.ibm.com/catalog?taxonomyNavigation=apps&category=containers)

# Prerequisites

<!-- Use [Deploying Gitlab to IBM Cloud Private](docs/deploy-with-ICP.md) if you wish to install this on IBM Cloud Private, otherwise follow the instructions below. -->

Create a Kubernetes cluster with either [Minikube](https://kubernetes.io/docs/setup/minikube/) for local testing, or with [IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers/cs_tutorials.html#cs_cluster_tutorial) to deploy in cloud. The code here is regularly tested against [Kubernetes Cluster from IBM Cloud Kubernetes Service](https://cloud.ibm.com/docs/containers/cs_ov.html#cs_ov) using Travis.

[Helm](https://helm.sh/) to install GitLab's Cloud Native charts.

# Steps

1. [Clone the repo](#1-clone-the-repo)
2. [Create IBM Cloud Kubernetes Service](#2-create-ibm-cloud-kubernetes-service)
3. [Install Helm](#3-install-helm)
4. [Configure GitLab and Install](#4-configure-gitlab-and-install)
5. [Launch GitLab](#5-launch-gitlab)

### 1. Clone the repo

Clone the repo and go in the cloned directory
```
$ git clone https://github.com/IBM/Kubernetes-container-service-GitLab-sample/
```

### 2. Create IBM Cloud Kubernetes Service

Create an IBM Cloud Kubernetes Service if you don't already have one:

* [IBM Cloud Kubernetes Service](https://cloud.ibm.com/containers-kubernetes/catalog/cluster)

### 3. Install Helm

If you don't have the Helm client in your machine, you can find one in the [official releases page](https://github.com/helm/helm/releases).

To install Helm in your Kubernetes Cluster, do:

```
$ helm init
```

Add the official gitlab repo:

```
$ helm repo add gitlab https://charts.gitlab.io/
$ helm repo update
```

To verify installation of Helm in your cluster:

```
$ helm version

Client: &version.Version{SemVer:"v2.11.0", GitCommit:"2e55dbe1fdb5fdb96b75ff144a339489417b146b", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.11.0", GitCommit:"2e55dbe1fdb5fdb96b75ff144a339489417b146b", GitTreeState:"clean"}
```

> For more info in installing helm, you can find the official documentation [here](https://docs.helm.sh/using_helm/#installing-helm). The helm version that you install should be the same version or a previous version to the version of the cluster (i.e. the Server version in `helm version`). If the helm version is newer than the cluster, the command may not work as expected.

### 4. Configure GitLab and Install

You can find the official helm chart repo for Cloud Native GitLab deployment [here](https://gitlab.com/charts/gitlab). This can guide you in configuring your own deployment for production use.

A sample configuration `config.yaml` in this repo can help you get started with GitLab in IKS. This yaml file is configured to use the provided ingress controller with IKS. The components (Gitaly, Postgres, Redis, Minio) will not use any persistent storage for now.

Modify `config.yaml` file to use your own Ingress Subdomain, certificate, and IP.

```
$ bx cs cluster-get <CLUSTER_NAME>

## You should look for these values
## ...
## Ingress Subdomain:	anthony-dev.us-south.containers.appdomain.cloud
## Ingress Secret:	anthony-dev
## ...
```

To get the ALB (Application Load Balancer) IP address of your cluster:

```
$ bx cs albs --cluster <CLUSTER_NAME>

## Get the IP Address from the public ALB
## ALB ID             Enabled   Status     Type      ALB IP         Zone
## private-...-alb1   false     disabled   private   -              -
## public-...-alb1    true      enabled    public    169.XX.XX.XX   dal13
```

You can now fill in your own values of `INGERSS_SUBDOMAIN`, `INGRESS_SECRET`, and `ALB_IP` in `config.yaml`

Install GitLab by doing:

```
$ helm upgrade --install gitlab gitlab/gitlab -f config.yaml
```

### 5. Launch GitLab

Installing GitLab can take minutes to setup. You can check the status of your deployment:

```
$ kubectl get pods

NAME                                       READY     STATUS             RESTARTS   AGE
gitlab-gitaly-0                            1/1       Running            0          3m
gitlab-gitlab-runner-7554ff7c9d-2rt7x      0/1       Running            4          3m
gitlab-gitlab-shell-78b8677b59-9z9m2       1/1       Running            0          3m
gitlab-gitlab-shell-78b8677b59-hssqc       1/1       Running            0          2m
gitlab-migrations.1-74xqt                  0/1       Completed          0          3m
gitlab-minio-7b67585cf5-tc4gh              1/1       Running            0          3m
gitlab-minio-create-buckets.1-bdbhk        0/1       Completed          0          3m
gitlab-postgresql-7756f9c75f-pzvlj         1/1       Running            0          3m
gitlab-redis-554dc46b4c-jlkps              2/2       Running            0          3m
gitlab-registry-75cdd8cc6d-n6fx6           1/1       Running            0          2m
gitlab-registry-75cdd8cc6d-nz9sq           1/1       Running            0          3m
gitlab-sidekiq-all-in-1-5865f7f999-wvg6c   1/1       Running            0          3m
gitlab-task-runner-d84b7b9b9-9mc9k         1/1       Running            0          3m
gitlab-unicorn-596cbf98cc-kqrsr            2/2       Running            0          3m
gitlab-unicorn-596cbf98cc-mjbtn            2/2       Running            0          2m
```

If all your pods are now running, you can now go to your GitLab installation by visiting `https://gitlab.<INGRESS_SUBDOMAIN>`

Now that Gitlab is running you can [register as a new user and create a project](docs/using-gitlab.md).

To try GitLab with persistent storage, you can explore `config-persistent.yaml` and use that instead of `config.yaml`. This will use dynamic storage provisioning that's provided with IKS.

You can learn how to expose the port `22` [here](docs/ssh-port-ingress.md) with the ingress controller to clone repositories using SSH.

# Troubleshooting

If a pod doesn't start examine the logs.
```bash
kubectl get pods
kubectl logs <pod name>
```

# Cleanup

To delete your GitLab installation:

```bash
$ helm delete gitlab --purge
```

# License

This code pattern is licensed under the Apache Software License, Version 2. Separate third party code objects invoked within this code pattern are licensed by their respective providers pursuant to their own separate licenses. Contributions are subject to the Developer [Certificate of Origin, Version 1.1](https://developercertificate.org/) (“DCO”) and the [Apache Software License, Version 2](LICENSE).

ASL FAQ link: https://www.apache.org/foundation/license-faq.html#WhatDoesItMEAN


