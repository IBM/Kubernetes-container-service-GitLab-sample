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

First, let's create a directory for our scenario:

```text
$ mkdir gitlabexercise
$ cd gitlabexercise
```

### 2. Create Dockerfiles

For this exercise, we will need a total of three containers, one each for
Redis, Postgresql, and Gitlab.  Docker images must be specially created for
the z Systems platform, and currently there a limited number of these that
exist.  But lucky for us, there is already an image for
[Redis](https://hub.docker.com/r/s390x/redis/), so we will be using it!

For Gitlab and Postgresql, however, s390x images do not exist, so we will have
to get a bit creative.  For Gitlab, the heavy lifting has already been done
for us in a separate
[repo](https://github.com/IBM/container-service-gitlab-sample).  We merely
need to copy the contents of the Gitlab container directory, which consists of
two install scripts and a Dockerfile.  Thanks to the portability of docker
images, all we have to do is change the first line of the Dockerfile from
`FROM alpine:3.5` to `FROM s390x/alpine`

The only Dockerfile we will need to write is for Postgresql:

Dockerfile-postgres

```text
#
# example Dockerfile for https://docs.docker.com/examples/postgresql_service/
#

FROM s390x/ubuntu

RUN apt-get update && apt-get upgrade -y

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y python-software-properties software-properties-common postgresql postgresql-client postgresql-contrib

# Note: The official Debian and Ubuntu images automatically ``apt-get clean``
# after each ``apt-get``

# Run the rest of the commands as the ``postgres`` user created by the ``postgres`` package when it was ``apt-get installed``
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
    createdb -O docker docker

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.5/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/9.5/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/9.5/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/9.5/bin/postgres", "-D", "/var/lib/postgresql/9.5/main", "-c", "config_file=/etc/postgresql/9.5/main/postgresql.conf"]
```

### 3. Define service in a Compose file

Again, we are going to use docker-compose to manage our Docker images.  In the
project directory, create a `docker-compose.yml` file that contains a slightly
modified version of the file by the same name in the root of the
[repo](https://github.com/IBM/container-service-gitlab-sample) from which we
borrowed our gitlab dockerfile:

```text
postgresql:
  restart: always
#  image: registry.ng.bluemix.net/${NAMESPACE}/gitlab-postgres:latest
  build: .
  dockerfile: Dockerfile-postgres
  environment:
    - DB_USER=gitlab
    - DB_PASS=password
    - DB_NAME=gitlabhq_production
  volumes:
    - postgresql:/var/lib/postgresql:rw
gitlab:
  restart: always
#  image: registry.ng.bluemix.net/${NAMESPACE}/gitlab:latest
  build: .
  dockerfile: Dockerfile-gitlab
  links:
    - redis:redis
    - postgresql:postgresql
  ports:
    - "80:80"
    - "22:22"
  environment:
    - GITLAB_HOST=my.gitlab-server
  volumes:
    - gitlab:/home/git/data:rw
redis:
  restart: always
#  image: registry.ng.bluemix.net/${NAMESPACE}/redis:latest
  image: s390x/redis
  volumes:
    - redis:/var/lib/redis:rw
```

### 4. Build and run

```text
$ docker-compose up -d --build
```
