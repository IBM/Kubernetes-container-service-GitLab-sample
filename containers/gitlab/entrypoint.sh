#!/bin/sh
set -x

#test for DB credentials as a file and parse into user, pass, host and port
if [ -f /opt/postgres-svc/binding ]
then
  DB_USER=$(grep uri\" /opt/postgres-svc/binding | cut -f 3 -d/ | cut -f 1 -d:)
  DB_PASS=$(grep uri\" /opt/postgres-svc/binding | cut -f 3 -d/ | cut -f 2 -d: | cut -f 1 -d@)
  DB_HOST=$(grep uri\" /opt/postgres-svc/binding | cut -f 3 -d/ | cut -f 2 -d: | cut -f 2 -d@)
  DB_PORT=$(grep uri\" /opt/postgres-svc/binding | cut -f 3 -d/ | cut -f 3 -d:)
fi

#set defaults or use previously defined from environment
DB_HOST=${DB_HOST:-postgresql}
DB_PORT=${DB_PORT:-5432}
REDIS_HOST=${REDIS_HOST:-redis}
REDIS_PORT_NUM=${REDIS_PORT_NUM:-6379}
GITLAB_HOST=${GITLAB_HOST:-gitlab-server}
GITLAB_DB_USER=${DB_USER:-git}
GITLAB_DB_NAME=${GITLAB_DB_NAME:-gitlabhq_production}

create_database_config() {
cat <<EOF > /home/git/gitlab/config/database.yml
#
# PRODUCTION
#
production:
  adapter: postgresql
  encoding: unicode
  database: ${GITLAB_DB_NAME}
  pool: 10
  username: ${GITLAB_DB_USER}
  password: ${DB_PASS}
  host: ${DB_HOST}
  port: ${DB_PORT}
EOF
}


create_redis_config() {
cat <<EOF > /home/git/gitlab/config/resque.yml
production:
  url: redis://${REDIS_HOST}:${REDIS_PORT_NUM}
EOF
}



start_sshd() {
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
	ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi
if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
	ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi

if [ ! -d "/var/run/sshd" ]; then
  mkdir -p /var/run/sshd
fi

/usr/sbin/sshd -E /var/log/sshd.log &
}

update_nginx_conf() {
cp /home/git/gitlab/lib/support/nginx/gitlab /etc/nginx/conf.d/default.conf
sed -ie 's/server unix:.*\.socket/server localhost:8181/' /etc/nginx/conf.d/default.conf
sed -ie 's/events {/pid \/var\/run\/nginx.pid;\n\nevents {/' /etc/nginx/nginx.conf
sed -ie "s/server_name YOUR_SERVER_FQDN/server_name ${GITLAB_HOST}/" /etc/nginx/conf.d/default.conf
}


update_gitlab_conf() {
cd /home/git/gitlab/config
sed -ie 's!default: /home/git/repositories!default: /home/git/data/repositories!g' gitlab.yml
sed -ie "s/host: localhost/host: ${GITLAB_HOST}/" gitlab.yml
sed -ie "\$s/\$/${GITLAB_HOST}/" /etc/hosts

chmod 775 /home/git/data
adduser git root
sudo -u git mkdir /home/git/data/repositories
sudo -u git chmod -R ug+rwX,o-rwx /home/git/data/repositories/
sudo -u git chmod -R ug-s /home/git/data/repositories/

delgroup git root
chmod 755 /home/git/data
}


setup_database() {

# if we are using postresql as a bound service, create database for github here
if [ ${DB_USER} ]
then
  PGPASSWORD="${DB_PASS}" psql -v ON_ERROR_STOP=1 -h "${DB_HOST}" -p "${DB_PORT}" --username "${DB_USER}" -d template1 <<-EOSQL
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      CREATE DATABASE "$GITLAB_DB_NAME" OWNER "$DB_USER";
      GRANT ALL PRIVILEGES ON DATABASE "$GITLAB_DB_NAME" TO "$DB_USER";
EOSQL
fi

cd /home/git/gitlab

RS=$(PGPASSWORD=${DB_PASS} psql -h ${DB_HOST} -p ${DB_PORT} -U ${GITLAB_DB_USER} -d ${GITLAB_DB_NAME} -Atwc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';")
if [[ $RS -eq 0  ]]; then
	sudo -u git -H force=yes bundle exec rake gitlab:setup RAILS_ENV=production
fi

}

start_gitlab() {
app_user="git"
workhorse_dir="/home/${app_user}/gitlab-workhorse"

cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:shell:install REDIS_URL=redis://${REDIS_HOST}:${REDIS_PORT_NUM} RAILS_ENV=production # SKIP_STORAGE_VALIDATION=true

WORKHORSE_OPTIONS="-authBackend http://127.0.0.1:8080"
PATH=$workhorse_dir:$PATH /home/git/gitlab-workhorse/gitlab-workhorse $WORKHORSE_OPTIONS &

sudo -u git -H RAILS_ENV=production bin/background_jobs start &
sudo -u git -H RAILS_ENV=production bin/web start &

nginx -g "daemon off;"
}

create_database_config
create_redis_config
update_gitlab_conf
setup_database
update_nginx_conf
start_sshd
start_gitlab
