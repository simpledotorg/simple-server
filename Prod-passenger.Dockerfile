# Ruby version 2.7.4
FROM phusion/passenger-ruby27:2.0.1

SHELL ["/bin/bash", "-c"]

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Enable nginx
RUN rm -f /etc/service/nginx/down

# Remove default nginx site
RUN rm /etc/nginx/sites-enabled/default

# Add nginx site for simple-server
ADD webapp.conf /etc/nginx/sites-enabled/webapp.conf

# Default directory setup
ENV INSTALL_PATH /home/app
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

# Copy application files
COPY --chown=app:app ./ $INSTALL_PATH

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
# Install cron
RUN apt-get install -y cron
# Install vim
RUN apt-get install -y vim

# Configure rails env
ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV BUNDLE_VERSION 2.2.29

# Build
RUN gem install bundler -v $BUNDLE_VERSION
RUN bundle install
RUN yarn install
RUN set -a && source .env.development && set +a && bundle exec rake assets:precompile
RUN chown -R app:app /home/app

ENTRYPOINT ["/home/app/bin/docker-entrypoint"]
