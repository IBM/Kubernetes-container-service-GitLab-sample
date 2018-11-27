# Deploy gitlab with docker

## 1. Install Docker CLI 

First, install [Docker](https://www.docker.com) by following the instructions [here](https://www.docker.com/community-edition#/download) for your preferred operating system.

## Single Container deployment via Docker

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

It's easy to connect gitlab to external PostgreSQL and Redis services by making a few tweaks to the environment variables passed to the gitlab container.  In the root of this repo is a [docker-compose.yml](../docker-compose.yml) file which will demonstrate a multiple container deployment that you can run locally or against a remote docker server.

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
