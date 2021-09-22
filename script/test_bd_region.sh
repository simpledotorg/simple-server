#!/usr/bin/env bash
set -ex

bin/rails db:drop
bin/rails db:create
psql simple-server_development < $1
bin/rails db:environment:set RAILS_ENV=development
bin/rails db:refresh_matviews
bin/rails db:migrate
