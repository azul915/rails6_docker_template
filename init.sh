#!/bin/bash

function usage {
  cat <<'EOM'
Usage: /bin/bash init.sh [OPTIONS] [VALUE]
Options:
  -h            Display help
  -p  [VALUE]   Give a project's name[required]
  -r  [VALUE]   Define a mysql root password[required]
EOM
  exit 1
}

while getopts ":p:r:h" optKey; do
  case "$optKey" in
    p)
      project_name=$OPTARG
      ;;
    r)
      root_password=$OPTARG
      ;;
    '-h'|'--help'|* )
      usage
      ;;
  esac
done

if [ -z $project_name ] || [ -z $root_password ]; then
  echo -e "you must define project name and mysql root password.\n"
  usage
  exit 1
fi

# echo -e "docker-compose down -v\n"
# docker-compose down -v
echo -e "delete all directories and files except init.sh and README.md\n"
ls | grep -v -E 'init.sh|README.md' | xargs rm -rf

echo -e "start!!\n"
echo -e "make a Dockefile for rails container under ./docker\n"
cat <<'EOF' > web.dockerfile
FROM ruby:2.7.0

ENV LANG C.UTF-8
ENV APP_ROOT /usr/src
ENV TZ Asia/Tokyo

WORKDIR $APP_ROOT
RUN set -ex && \
    apt-get update -qq && \
    apt-get install -y sudo && \
    : "Install node.js" && \
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - && \
    apt-get update -qq && \
    apt-get install -y nodejs && \
    : "Install yarn" && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update -qq && \
    apt-get install -y yarn && \
    : "Install rails6.X latest version" && \
    gem install rails --version="~>6.0.0"
EOF
mkdir ./docker && mv web.dockerfile ./docker/

echo -e "make a config files for mysql container under ./mysql-confd\n"
mkdir ./mysql-confd
cat <<EOF > locale.gen
ja_JP.UTF-8 UTF-8
EOF
mv locale.gen ./mysql-confd

cat <<EOF > charset.cnf
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_general_ci

[client]
default-character-set=utf8mb4
EOF
mv charset.cnf ./mysql-confd

cat <<EOF > mysql.cnf
[mysqld]
default_authentication_plugin=mysql_native_password
EOF
mv mysql.cnf ./mysql-confd

echo -e "make a Dockerfile for mysql container under ./docker\n"
cat <<EOF > db.dockerfile
FROM mysql:8.0

COPY ./mysql-confd/locale.gen /etc/locale.gen
RUN set -ex && \
    apt-get update -qq && \
    apt-get install -y locales && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8
EOF
mv db.dockerfile ./docker/

echo -e "make a docker-compose.yml\n"
cat <<EOF > docker-compose.yml
version: '3.7'
services:
  db:
    build:
      context: .
      dockerfile: ./docker/db.dockerfile
    container_name: rails_mysql
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: $root_password
      TZ: 'Asia/Tokyo'
    volumes:
      - ./mysql:/var/lib/mysql
      - ./mysql-confd:/etc/mysql/conf.d
  web:
    build:
      context: .
      dockerfile: ./docker/web.dockerfile
    container_name: rails_web
    volumes:
      - ./$project_name/:/usr/src/$project_name/
    ports:
      - "3000:3000"
    environment:
      PORT: 3000
      BINDING: 0.0.0.0
    stdin_open: true
    tty: true
    links:
      - db
EOF

echo -e "docker-compose build\n"
docker-compose build

echo -e "docker-compose up -d\n"
docker-compose up -d

echo -e "rails new $project_name --database=mysql\n"
docker-compose exec web rails new $project_name --database=mysql

echo Rewrite ./$project_name/config/database.yml for connection of MySQL container
sed -i -e "s/password:/password: $root_password/g" ./$project_name/config/database.yml
sed -i -e 's/host: localhost/host: db/g' ./$project_name/config/database.yml

echo -e "rails db:create\n"
docker-compose exec web /bin/sh -c \
  "cd /usr/src/$project_name && \
  rails db:create"

echo -e "rails server\n"
docker-compose exec web /bin/sh -c \
  "cd /usr/src/$project_name && \
  rails server"
