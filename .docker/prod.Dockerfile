# Base image from https://github.com/simpledotorg/container-deployment/blob/master/docker/simple-server-base.Dockerfile
FROM simpledotorg/server-base:latest

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
ADD .docker/config/nginx/webapp.conf /etc/nginx/sites-enabled/webapp.conf

# Add logrotate config
ADD .docker/config/logrotate/* /etc/logrotate.d/
RUN chmod 644 /etc/logrotate.d/*

# Default directory setup
ENV INSTALL_PATH /home/app
RUN mkdir -p $INSTALL_PATH
WORKDIR $INSTALL_PATH

# Create cron logs directory
RUN mkdir -p /home/deploy/apps/simple-server/shared/log

# Copy application files
COPY --chown=app:app ./ ./

# Configure rails env
ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true

# Build
RUN gem install bundler -v "$(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1)"
RUN bundle install --without development test
RUN yarn install
RUN set -a && source .env.development && set +a && bundle exec rake assets:precompile
RUN chown -R app:app /home/app

ENTRYPOINT ["/home/app/bin/docker-entrypoint"]
