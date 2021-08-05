source "https://rubygems.org"

ruby "2.6.6"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "dotenv-rails"
gem "rails", "5.2.6"

gem "active_hash", "~> 2.3.0"
gem "active_record_union"
gem "activerecord-import"
gem "amazing_print"
gem "auto_strip_attributes"
gem "bcrypt", "~> 3.1", ">= 3.1.11"
gem "bootsnap", require: false
gem "bootstrap", "~> 4.5.0"
gem "bootstrap_form", ">= 4.5.0"
gem "bootstrap-datepicker-rails", "~> 1.9"
gem "connection_pool"
gem "data-anonymization", require: false
gem "data_migrate"
gem "ddtrace", "~> 0.51"
gem "devise", ">= 4.7.1"
gem "devise_invitable", "~> 1.7.0"
gem "dhis2", require: false
gem "diffy" # This gem is only needed for Admin::FixZoneDataController, it should be removed with the controller
gem "discard", "~> 1.0"
gem "dogstatsd-ruby", "~> 5.2"
gem "factory_bot_rails", "~> 6.1", require: false
gem "faker", require: false
gem "flipper"
gem "flipper-active_record"
gem "flipper-ui"
gem "friendly_id", "~> 5.2.4"
gem "github-ds"
gem "groupdate"
gem "http"
gem "http_accept_language"
gem "imgkit"
gem "jbuilder", "~> 2.5"
gem "jquery-rails"
gem "kaminari"
gem "lodash-rails"
gem "lograge"
gem "ougai"
gem "oj"
gem "parallel", require: false
gem "passenger"
gem "pg", ">= 0.18", "< 2.0"
gem "pg_search"
gem "pg_ltree", "1.1.8"
gem "phonelib"
gem "pry-rails"
gem "rack-mini-profiler"
gem "redis"
gem "request_store"
gem "request_store-sidekiq"
gem "roo", "~> 2.8.0"
gem "rspec-rails", "~> 4.0.1"
gem "rswag", "~> 1.6.0"
gem "ruby-progressbar", require: false
gem "rubyzip"
gem "sassc-rails"
gem "scenic"
gem "scientist"
gem "sentry-rails"
gem "sentry-ruby"
gem "sentry-sidekiq"
gem "sidekiq"
gem "sidekiq-statsd"
gem "sidekiq-throttled"
gem "slack-notifier"
gem "timecop", "~> 0.9.0", require: false
gem "twilio-ruby", "~> 5.10", ">= 5.10.3"
gem "uglifier", ">= 1.3.0"
gem "uuidtools", require: false
gem "view_component", require: "view_component/engine"
gem "whenever", require: false
gem "wkhtmltoimage-binary"
gem "memery"
gem "bootstrap-select-rails"
gem "render_async"
gem "rack-attack"
gem "squid"

group :development, :test do
  gem "active_record_query_trace", require: false
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "capistrano", "3.11.0"
  gem "capistrano-db-tasks", require: false
  gem "capistrano-multiconfig", require: true
  gem "capistrano-passenger", "0.2.1"
  gem "capistrano-rails"
  gem "capistrano-rails-console", require: false
  gem "capistrano-rbenv"
  gem "capistrano-sentry", require: false
  gem "capistrano-template", require: false
  gem "parallel_tests", group: %i[development test]
  gem "rails-controller-testing"
  gem "rb-readline"
  gem "shoulda-matchers", "~> 4.1.2"
  gem "standard", "1.1.0", require: false
end

group :development do
  gem "guard-rspec", require: false
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "rails-erd"
  gem "spring"
  gem "spring-commands-rspec"
  gem "web-console", ">= 3.3.0"
  gem "memory_profiler"
  gem "flamegraph"
  gem "stackprof"
end

group :test do
  gem "capybara"
  gem "generator_spec"
  gem "launchy"
  gem "mock_redis", require: false
  gem "puma"
  gem "rspec-sidekiq"
  gem "simplecov", require: false
  gem "webdrivers"
  gem "webmock"
end
