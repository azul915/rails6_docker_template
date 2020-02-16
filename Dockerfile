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

# TODO: プロジェクトルートに空のGemfileとGemfile.lockを置いてbundle installできるか試す
# MEMO: docker exec -it rails_web /bin/bash
# MEMO: rails new [project_name] --force --database=mysql --skip-bundle
# MEMO: ./config/database.ymlを password: root, host: db に書き換え
# ADD Gemfile $APP_ROOT/Gemfile
# ADD Gemfile.lock $APP_ROOT/Gemfile.lock

# RUN bundle install