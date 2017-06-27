# Deploy with Docker on LinuxONE

Open source software has expanded from a low-cost alternative to a platform for enterprise databases, clouds and next-generation apps. These workloads need higher levels of scalability, security and availability from the underlying hardware infrastructure.

LinuxONE was built for open source so you can harness the agility of the open revolution on the industry’s most secure, scalable and high-performing Linux server. In this journey we will show how to run open source Cloud-Native workloads on LinuxONE

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

In this exercise, we will be creating our own custom docker images.  To do so,
we will need a base image upon which to build.  Our first step in creating a
base RHEL image to get a copy of the `mkimage-yum.sh` script from the [Moby
project](https://mobyproject.org)

```text
$ wget https://github.com/moby/moby/blob/master/contrib/mkimage-yum.sh
```
To create a RHEL image, comment out the second and third to last lines:
```text
#tar –numeric-owner -c -C “$target” . | docker import - $name:$version
#docker run -i -t $name:$version echo success
```
And add the line:
```text
tar –numeric-owner -c -C “$target” . -zf ${name}.tar.gz
```
Next, create the RHEL tarball:
```text
./mkimage-yum.sh rhel7_docker
```
Finally, create your docker RHEL7 image:
```text
cat rhel7_docker.tar.gz | sudo docker import -<YOUR_NAME>/rhel7
```
You will need to replace `<YOUR_NAME>` with your docker hub registration name.


You will also need a `requirements.txt` file in the directory with the contents:

```text
gitlab
postgres
redis
```

### 2. Create Dockerfiles

Next we need to write a few Dockerfiles to build our Docker images.  In the
project directory, create the following two files with their respective
content, remebering to replace `<YOUR_NAME>` with your docker hub registration
name:

Dockerfile-gitlab
```text
FROM <YOUR_NAME>/rhel7

# update rhel base image
RUN yum update

# Install required packages
RUN yum install ca-certificates \
      openssh-server \
      wget \
      apt-transport-https \
      vim \
      apt-utils \
      curl \
      postfix \
      nano

# Install the gitlab 
RUN yum install gitlab

# Manage SSHD through runit
RUN mkdir -p /opt/gitlab/sv/sshd/supervise \
    && mkfifo /opt/gitlab/sv/sshd/supervise/ok \
    && printf "#!/bin/sh\nexec 2>&1\numask 077\nexec /usr/sbin/sshd -D" > /opt/gitlab/sv/sshd/run \
    && chmod a+x /opt/gitlab/sv/sshd/run \
    && ln -s /opt/gitlab/sv/sshd /opt/gitlab/service \
    && mkdir -p /var/run/sshd

# Disabling use DNS in ssh since it tends to slow connecting
RUN echo "UseDNS no" >> /etc/ssh/sshd_config

# Prepare default configuration
RUN ( \
  echo "" && \
  echo "# Docker options" && \
  echo "# Prevent Postgres from trying to allocate 25% of total memory" && \
  echo "postgresql['shared_buffers'] = '1MB'" ) >> /etc/gitlab/gitlab.rb && \
  mkdir -p /assets/ && \
  cp /etc/gitlab/gitlab.rb /assets/gitlab.rb

# Expose web & ssh
EXPOSE 443 80 22

# Define data volumes
VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]

# Copy assets
COPY assets/wrapper /usr/local/bin/

# Wrapper to handle signal, trigger runit and reconfigure GitLab
CMD ["/usr/local/bin/wrapper"]
```

Dockerfile-postgres

```text
#
# example Dockerfile for https://docs.docker.com/examples/postgresql_service/
#

FROM <YOUR_NAME>/rhel7

RUN yum update

# Add the PostgreSQL PGP key to verify their Debian packages.
# It should be the same key as https://www.postgresql.org/media/keys/ACCC4CF8.asc
RUN apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8

# Install ``python-software-properties``, ``software-properties-common`` and PostgreSQL
#  There are some warnings (in red) that show up during the build. You can hide
#  them by prefixing each apt-get statement with DEBIAN_FRONTEND=noninteractive
RUN yum install python-software-properties software-properties-common postgresql postgresql-client postgresql-contrib

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
project directory, create a `docker-compose.yml` file that contains:
```text
version: '2'
services:
  gitlab:
    build: Dockerfile-gitlab
  postgres:
    build: Dockerfile-postgres
  redis:
    image: "s390x/redis"
```

### 4. Build and run

```text
$ docker-compose up
```
