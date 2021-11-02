#!/usr/bin/env bash
set -e

export DEFAULT_COUNTRY="BD"
export REFRESH_MATVIEWS_CONCURRENTLY=0

bin/rails db:drop
bin/rails db:create
psql simple-server_development < $1
bin/rails db:environment:set RAILS_ENV=development
bin/rails db:refresh_matviews
bin/rails db:migrate
script/run_data_script update_bangladesh_regions_script
bin/rails 'create_admin_user[admin,admin@simple.org,Resolve2SaveLives]'

echo "You can now run the real thing with dry_run turned off with:"
echo
echo "  DEFAULT_COUNTRY=BD script/run_data_script update_bangladesh_regions_script true"