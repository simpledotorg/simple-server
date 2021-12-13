FROM ruby:2.7.4

RUN apt-get update && apt-get install -y yarn redis-server postgresql-client nodejs jq

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./

COPY . .

RUN gem install bundler -v 2.2.29
RUN bundle _2.2.29_ install
RUN rake yarn:install
