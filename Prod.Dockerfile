# Dockerfile development version
FROM ruby:2.7.4

SHELL ["/bin/bash", "-c"] 

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

# Configure rails env
ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true

# Build
RUN gem install bundler -v $BUNDLE_VERSION
RUN bundle config --global frozen 1
RUN bundle config set --local without 'development test'
RUN bundle install
RUN yarn install
RUN set -a && source .env.development && set +a && bundle exec rake assets:precompile

# Remove all default .env config files
RUN rm -f .env.*

EXPOSE 3000
ENTRYPOINT ["/opt/app/bin/docker-entrypoint"]
CMD ["rails", "server", "-b", "0.0.0.0"]
