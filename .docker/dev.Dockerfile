# Dockerfile development version
FROM ruby:2.7.8

# ruby:2.7.8 is based on Debian 11 (bullseye), which is end-of-life. Its packages
# have moved from deb.debian.org to archive.debian.org, whose Release files are expired.
RUN sed -i 's|http://deb.debian.org|http://archive.debian.org|g; /bullseye-updates/d' /etc/apt/sources.list \
 && echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99archive

ENV BUNDLE_VERSION 2.4.22
ENV EDITOR vim

## Install dependencies
# Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg -o /root/yarn-pubkey.gpg && apt-key add /root/yarn-pubkey.gpg
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN apt-get update && apt-get install -y --no-install-recommends yarn
# Redis and Postgres
RUN apt-get update && apt-get install -y redis-server postgresql-client jq
# Node  
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get update && apt-get install -y --no-install-recommends nodejs
# Install vim
RUN apt-get install -y vim

# Default directory
ENV INSTALL_PATH /opt/app
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

COPY . .

# Install gems
RUN gem install bundler -v $BUNDLE_VERSION
RUN bundle install
RUN yarn install
