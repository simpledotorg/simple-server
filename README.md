# RedApp Server

[![Build Status](https://semaphoreci.com/api/v1/simpledotorg/simple-server/branches/master/badge.svg)](https://semaphoreci.com/simpledotorg/simple-server)

This is the backend for the Simple app to help track hypertensive patients across a population.

## Setup
First, you need to install ruby: https://www.ruby-lang.org/en/documentation/installation/
```bash
gem install bundler
bundle install
rake db:create db:setup db:migrate
```

## Configuring
The app can be configured using a .env file. Look at .env.development for sample configuration

## Running the application locally
The application will start at http://localhost:3000.
```bash
RAILS_ENV=development bundle exec rails server
```

## Running the tests
```bash
RAILS_ENV=test bundle exec rspec
```

## Documentation
- API Documentation can be accessed at /api-docs on local server
  - They are also available https://api.simple.org/api-docs
- Architecture decisions are captured in ADR format and are available in /doc/arch

## Deployment
simple-server is deployed to the enviroment using capistrano.
```bash
bundle exec cap <enviroment> deploy
# eg: bundle exec cap staging deploy
```

Rake tasks can be run on the deployed server using capistrano as well. For example,
```bash
bundle exec cap staging deploy:rake task=db:seed
```
