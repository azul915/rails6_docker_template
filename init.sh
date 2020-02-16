#!/bin/bash

echo "docker pull ruby;2.7.0"
docker pull ruby:2.7.0

echo "docker pull mysql:8.0"
docker pull mysql:8.0

echo "docker images"
docker images

echo "make Dockefile"
cat <<'EOF' > Dockerfile
FROM ruby:2.7.0

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

ENV LANG C.UTF-8
ENV APP_ROOT /usr/src

WORKDIR $APP_ROOT

EOF

echo "make docker-compose.yml"
cat <<'EOF' > docker-compose.yml
version: '3'
services:
  db:
    image: mysql:8.0
    container_name: rails_mysql
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_PASSWORD: password
      TZ: 'Asia/Tokyo'
    command: mysqld --default-authentication-plugin=mysql_native_password --character-set-server=utf8mb4 --collation-server=utf8mb4_ja_0900_as_cs

  web:
    build: .
    container_name: rails_web
    volumes:
      - .:/usr/src
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

echo "Compose-Up WebContainer and DBContainer."
echo "docker-compose up -d"
docker-compose up -d

echo "Create a new project."
echo "docker-compose run web rails new $1 --datebase=mysql"
docker-compose run web rails new project --datebase=mysql

echo "Rewrite ./config/database.yml for connection of MySQL container"
sed -i -e 's/password:$/password: password/g' $1/config/database.yml
sed -i -e 's/host: localhost$/host: db/g' $1/config/database.yml

echo "Create a Database."
echo "rails db:crate"
docker-compose run web rails db:create --workdir="/usr/src/$1"

echo "Start rails server."
echo "docker-compose run web rails server"
docker-compose run web rails server --workdir="/usr/src/$1"