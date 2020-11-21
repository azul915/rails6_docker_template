FROM ruby:2.7.0

ENV LANG C.UTF-8
ENV TZ Asia/Tokyo

WORKDIR /usr/src
RUN sed -i 's@archive.ubuntu.com@ftp.jaist.ac.jp/pub/Linux@g' /etc/apt/sources.list
RUN set -ex && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends sudo && \
    : "Install node.js" && \
    curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash - && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends nodejs && \
    : "Install yarn" && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends yarn && \
    : "Cleaning..." && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    : "Install rails6.X latest version" && \
    gem install rails --version="~>6.0.0"
