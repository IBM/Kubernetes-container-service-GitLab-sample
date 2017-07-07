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

You will also need a `requirements.txt` file in the directory with the contents:

```text
gitlab
postgres
redis
```

### 2. Create Dockerfiles

Next we need to write a few Dockerfiles to build our Docker images.  In the
project directory, create the following three files with their respective
content:

Dockerfile-gitlab
```text
M s390x/ubuntu

# update & upgrade the ubuntu base image
RUN apt-get update -y && apt-get upgrade -y

# Install required packages
RUN apt-get install -y build-essential \
      zlib1g-dev \
      libyaml-dev \
      libssl-dev \
      libgdbm-dev \
      libreadline-dev \
      libncurses5-dev \
      libffi-dev \
      curl \
      openssh-server \
      checkinstall \
      libxml2-dev \
      libxslt-dev \
      libcurl4-openssl-dev \
      libicu-dev \
      logrotate \
      python-docutils \
      pkg-config \
      cmake \
      nodejs

# Install Git
RUN apt-get install -y git-core

# Ruby
RUN mkdir /tmp/ruby
WORKDIR /tmp/ruby
RUN curl -O --progress https://cache.ruby-lang.org/pub/ruby/2.1/ruby-2.1.10.tar.gz
RUN tar xzf ruby-2.1.10.tar.gz
WORKDIR /tmp/ruby/ruby-2.1.10
RUN ./configure --disable-install-rdoc
RUN make
RUN make install
RUN gem install bundler --no-ri --no-rdoc

# Go
RUN apt install -y golang-go

# Create `git` user
RUN adduser --disabled-login --gecos 'Gitlab' git

# Database
RUN apt-get install -y postgresql-client libpq-dev

# Gitlab

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y gitlab; exit 0

# after install failure, fix gemfile
RUN sed -i "s|'gem "mysql2"'|'#gem "mysql2"' |g" /usr/share/gitlab/Gemfile
RUN sed -i "s|'gem "pg"'|'#gem "pg"' |g" /usr/share/gitlab/Gemfile
RUN sed -i "s|'gem "omniauth-kerbros"'|'#gem "omniauth-kerbros"' |g" /usr/share/gitlab/Gemfile
RUN sed -i "s|'gem "state_machines-activerecord", '~> 0.3.0''|'gem "state_machines-activerecord", '~> 0.5.0'' |g" /usr/share/gitlab/Gemfile
RUN echo "gem "pg", "~> 0.18.2"" >> /usr/share/gitlab/Gemfile

WORKDIR /usr/share/gitlab
RUN bundler; exit 0

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y pkg-config; exit 0

# add database connection and initialize
RUN sed -i "s|/var/run/postgresql|"postgresql/n  port:5432\n" |g" /usr/share/gitlab/config/database.yml

# configure redis
RUN sed -i "s|localhost|redis |g" /usr/share/gitlab/config/resque.yml

RUN sed -i "s|'app_user="git"'|'app_user="gitlab" |g" /etc/init.d/gitlab

USER gitlab
# initialize database
RUN bundle exec rake gitlab:setup RAILS_ENV=production

# compile assets
RUN bundle exec rake assets:precompile RAILS_ENV=production

# start gitlab instance
RUN service gitlab start

# nginx
RUN apt-get install -y nginx
RUN service nginx restart

# Expose web & ssh
EXPOSE 443 80 22

# Define data volumes
VOLUME ["/etc/gitlab", "/var/opt/gitlab", "/var/log/gitlab"]

# Wrapper to handle signal, trigger runit and reconfigure GitLab
#CMD ["/usr/local/bin/wrapper"]
CMD /etc/init.d/gitlab restart
```
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

Dockerfile-redis

```text
FROM        s390x/ubuntu
RUN         apt-get update && apt-get upgrade -y && apt-get install -y redis-server
EXPOSE      6379
ENTRYPOINT  ["/usr/bin/redis-server"]
```

### 3. Define service in a Compose file

Again, we are going to use docker-compose to manage our Docker images.  In the
project directory, create a `docker-compose.yml` file that contains a slightly
modified version of the file by the same name in the root of this repo:

```text
gitlab:
#  image: 'gitlab/gitlab-ce:9.1.0-ce.0'
  build: .
  dockerfile: Dockerfile-gitlab
  restart: always
  hostname: 'gitlab.example.com'
  links:
    - postgresql:postgresql
    - redis:redis
  environment:
    GITLAB_OMNIBUS_CONFIG: |
      postgresql['enable'] = false
      gitlab_rails['db_username'] = "gitlab"
      gitlab_rails['db_password'] = "gitlab"
      gitlab_rails['db_host'] = "postgresql"
      gitlab_rails['db_port'] = "5432"
      gitlab_rails['db_database'] = "gitlabhq_production"
      gitlab_rails['db_adapter'] = 'postgresql'
      gitlab_rails['db_encoding'] = 'utf8'
      redis['enable'] = false
      gitlab_rails['redis_host'] = 'redis'
      gitlab_rails['redis_port'] = '6379'
      external_url 'http://gitlab.example.com:30080'
      gitlab_rails['gitlab_shell_ssh_port'] = 30022
  ports:
# both ports must match the port from external_url above
    - "30080:30080"
# the mapped port must match ssh_port specified above.
    - "30022:22"
# the following are hints on what volumes to mount if you want to persist data
#  volumes:
#    - data/gitlab/config:/etc/gitlab:rw
#    - data/gitlab/logs:/var/log/gitlab:rw
#    - data/gitlab/data:/var/opt/gitlab:rw

postgresql:
  restart: always
#  image: postgres:9.6.2-alpine
  build: .
  dockerfile: Dockerfile-postgres
  environment:
    - POSTGRES_USER=gitlab
    - POSTGRES_PASSWORD=gitlab
    - POSTGRES_DB=gitlabhq_production
# the following are hints on what volumes to mount if you want to persist data
#  volumes:
#    - data/postgresql:/var/lib/postgresql:rw

redis:
  restart: always
#  image: redis:3.0.7-alpine
  build: .
  dockerfile: Dockerfile-redis
```

### 4. Build and run

```text
$ docker-compose up -d --build
```
