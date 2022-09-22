# Dockerfile development version
FROM ruby:2.7.4

ENV BUNDLE_VERSION 2.2.29

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

# Default directory
ENV INSTALL_PATH /opt/app
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

# Copy application files
COPY . .

# Install gems
RUN gem install bundler -v $BUNDLE_VERSION
RUN bundle install
RUN yarn install
