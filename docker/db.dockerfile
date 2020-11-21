FROM mysql:8.0

COPY ./mysql-confd/locale.gen /etc/locale.gen
RUN set -ex &&     apt-get update -qq &&     apt-get install -y locales &&     rm -rf /var/lib/apt/lists/* &&     locale-gen ja_JP.UTF-8
ENV LC_ALL ja_JP.UTF-8
