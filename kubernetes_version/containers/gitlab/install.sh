#!/bin/sh

echo -e '@community http://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories

BUILD_DEPENDS="
build-base
make
cmake
gcc
g++
zlib-dev
yaml-dev
postgresql-dev
gdbm-dev
readline-dev
ncurses-dev
libffi-dev
curl
openssh
libxml2-dev
libxslt-dev
icu-dev
logrotate
py2-docutils
go
ruby-dev
linux-headers
shadow
pkgconf"


PACKAGE_LIST="
ruby
ruby-bigdecimal
postgresql-client
nodejs
openssh
curl-dev
icu-libs
git
sudo
redis
nginx"


apk add --update --no-cache --virtual build-deps $BUILD_DEPENDS
  
apk add --no-cache $PACKAGE_LIST

usermod -p "*" git

# Required by bundler
gem install io-console bundler --no-ri --no-rdoc

# Yarn is not currently packaged by alpine linux and yarn recommends
# against installing via npm (i.e npm install -g yarn)
curl --location https://yarnpkg.com/install.sh | sudo -u git -H sh -

# Install gitlab
cd /home/git

sudo -u git -H git clone --depth=1 https://gitlab.com/gitlab-org/gitlab-ce.git -b 8-17-stable gitlab

cd /home/git/gitlab

# Copy the example GitLab config
sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml
sudo -u git -H cp config/database.yml.postgresql config/database.yml

# Update GitLab config file, follow the directions at top of file
#sed -ie 's/host: localhost/host: gitlab.localhost/g' config/gitlab.yml

# Copy the example secrets file
sudo -u git -H cp config/secrets.yml.example config/secrets.yml
sudo -u git -H chmod 0600 config/secrets.yml

# Create redis config file
sudo -u git -H cp config/resque.yml.example config/resque.yml

# Copy the example Unicorn config
sudo -u git -H cp config/unicorn.rb.example config/unicorn.rb

export NPROCS=`getconf _NPROCESSORS_ONLN`
sed -ie "s/worker_processes 3/worker_processes $NPROCS/" config/unicorn.rb

# Copy the example Rack attack config
sudo -u git -H cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb

# Make sure GitLab can write to the log/ and tmp/ directories
chown -R git log/ tmp/
chmod -R u+rwX,go-w log/
chmod -R u+rwX tmp/

# Make sure GitLab can write to the tmp/pids/ and tmp/sockets/ directories
chmod -R u+rwX tmp/pids/ tmp/sockets/

# Create the public/uploads/ directory
sudo -u git -H mkdir -p public/uploads/tmp
chown -R git /home/git/gitlab/public/uploads

# Make sure only the GitLab user has access to the public/uploads/ directory
chmod 0700 public/uploads

# Change the permissions of the directory where CI job traces and artifaccts are stored
chmod -R u+rwX builds/ shared/artifacts/

# Change the permissions of the directory where GitLab Pages are stored
chmod -R ug+rwX shared/pages/


mkdir ../repositories
chown -R git:git ../repositories

# Configure Git global settings for git user
# 'autocrlf' is needed for the web editor
sudo -u git -H git config --global core.autocrlf input

# Disable 'git gc --auto' because GitLab already runs 'git gc' when needed
sudo -u git -H git config --global gc.auto 0

# Enable packfile bitmaps
sudo -u git -H git config --global repack.writeBitmaps tru

# Ruby as installed by alpine doesn't provide tzinfo-data
sudo -u git -H echo "gem 'tzinfo-data'" >> Gemfile
sudo -u git -H bundle install --path /home/git/.gem --without development test mysql aws kerberos

sudo -u git -H bundle install --path /home/git/.gem --deployment --without development test mysql aws kerberos

sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production

# TODO: Create alpine linux init script
cp lib/support/init.d/gitlab /etc/init.d/gitlab

/home/git/.yarn/bin/yarn install --production --pure-lockfile
sudo -u git -H bundle exec rake gitlab:assets:compile RAILS_ENV=production NODE_ENV=production

# Clean up
rm -rf /home/git/.gem/ruby/*/cache/* /home/git/gitlab/vendor/bundle/ruby/*/cache*
rm -rf /home/git/gitlab/tmp/cache/*
apk del build-deps
rm -rf /var/cache/apk*
rm -rf /root/.cache
