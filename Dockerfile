FROM ruby:2.6.6

RUN apt-get update && apt-get install -y yarn redis-server postgresql-client nodejs jq

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./

COPY . .

RUN gem install bundler -v 1.17.3
RUN bundle _1.17.3_ install
RUN rake yarn:install
