# Deploy with Docker on LinuxONE

Open source software has expanded from a low-cost alternative to a platform for enterprise databases, clouds and next-generation apps. These workloads need higher levels of scalability, security and availability from the underlying hardware infrastructure.

LinuxONE was built for open source so you can harness the agility of the open revolution on the industry’s most secure, scalable and high-performing Linux server. In this journey we will show how to run open source Cloud-Native workloads on LinuxONE

It helps to start with a base OS image; in this case we will be
using Ubuntu ([s390x/ubuntu](https://hub.docker.com/r/s390x/ubuntu/)).  On top
of which we will install GitLab.

## Included Components

- [LinuxONE](https://www-03.ibm.com/systems/linuxone/open-source/index.html)
- [Docker](https://www.docker.com)
- [Docker Store](https://sore.docker.com)

## Prerequisites

Register at [LinuxONE Communinity Cloud](https://developer.ibm.com/linuxone/) for a trial account.
We will be using a Ret Hat base image for this journey, so be sure to chose the
'Request your trial' button on the left side of this page.

## Steps

### 1. Setup

First, install docker and docker-compose from the instructions in the LinuxONE
[repo](https://github.com/IBM/Cloud-Native-Workloads-on-LinuxONE)

Then let's create a directory for our scenario:

```shell
$ mkdir gitlabexercise
$ cd gitlabexercise
```

### 2. Copy scripts and  Dockerfiles

Copy the files found in the `linuxone` folder:

```shell
$ git clone https://github.com/IBM/Kubernetes-container-service-Gitlab-sample.git
$ cp Kubernetes-container-service-Gitlab-sample/linuxone/* .
```

### 3. Build and run

```text
$ docker-compose up -d --build
```

### 4. Navigate to gitlab

```text
http://[your_ip]:30080
```
And follow [these directions](using-gitlab.md) to register as a new user and
create a project.
