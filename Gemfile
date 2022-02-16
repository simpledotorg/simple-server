source "https://rubygems.org"
ruby "2.7.4"

plugin "bootboot", "~> 0.1.1"
Bundler.settings.set_local("bootboot_env_prefix", "RAILS")
Plugin.send(:load_plugin, "bootboot") if Plugin.installed?("bootboot")

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem "dotenv-rails"

if ENV["RAILS_NEXT"]
  enable_dual_booting if Plugin.installed?("bootboot")

  # Add any gem you want here, they will be loaded only when running
  # bundler command prefixed with `RAILS_NEXT=1`.
  gem "rails", "~> 6"
else
  gem "rails", "~> 5"
end

gem "active_hash", "~> 2.3.0"
gem "active_record_union"
gem "activerecord-import"
gem "amazing_print"
gem "auto_strip_attributes"
gem "bcrypt", "~> 3.1"
gem "bcrypt_pbkdf", "~> 1.1"
gem "bootsnap", require: false
gem "bootstrap_form", ">= 4.5.0"
gem "bootstrap-datepicker-rails", "~> 1.9"
gem "bootstrap-select-rails"
gem "bootstrap", "~> 4.5.0"
gem "connection_pool"
gem "data_migrate"
gem "data-anonymization", require: false
gem "ddtrace"
gem "devise_invitable", "~> 2.0.6"
gem "devise", ">= 4.7.1"
gem "dhis2", require: false
gem "diffy" # This gem is only needed for Admin::FixZoneDataController, it should be removed with the controller
gem "discard", "~> 1.2"
gem "dogstatsd-ruby", "~> 5.2"
gem "ed25519", "~> 1.2"
gem "factory_bot_rails", "~> 6.1", require: false
gem "faker", require: false
gem "flipper-active_record"
gem "flipper-ui"
gem "flipper"
gem "friendly_id", "~> 5.4.2"
gem "github-ds"
gem "google-protobuf", "~> 3.19"
gem "groupdate"
gem "http_accept_language"
gem "http"
gem "imgkit"
gem "jbuilder", "~> 2.5"
gem "jquery-rails"
gem "json-schema"
gem "kaminari"
gem "lodash-rails"
gem "lograge"
gem "memery"
gem "oj"
gem "ougai"
gem "parallel", require: false
gem "passenger"
gem "pg_ltree", "1.1.8"
gem "pg_search"
gem "pg", ">= 0.18", "< 2.0"
gem "phonelib"
gem "pry-rails"
gem "rack-attack"
gem "rack-mini-profiler", require: false
gem "redis"
gem "render_async"
gem "request_store-sidekiq"
gem "request_store"
gem "roo", "~> 2.8.0"
gem "rswag-api"
gem "rswag-ui"
gem "ruby-progressbar", require: false
gem "rubyzip"
gem "sassc-rails"
gem "scenic"
gem "scientist"
gem "sentry-rails"
gem "sentry-ruby"
gem "sentry-sidekiq"
gem "sidekiq-statsd"
gem "sidekiq-throttled"
gem "sidekiq"
gem "slack-notifier"
gem "squid"
gem "stackprof", require: false
gem "timecop", "~> 0.9.0", require: false
gem "twilio-ruby", "~> 5.62"
gem "uglifier", ">= 1.3.0"
gem "uuidtools", require: false
gem "view_component"
gem "webpacker", "6.0.0.rc.6"
gem "whenever", require: false
gem "wkhtmltoimage-binary"

group :development, :test do
  gem "active_record_query_trace", require: false
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "capistrano", "3.16.0"
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
  gem "rspec-rails", "~> 4"
  gem "rspec_junit_formatter"
  gem "rswag-specs"
  gem "shoulda-matchers", "~> 5.1.0"
  gem "standard", "1.6.0", require: false
end

group :development, :test, :profiling do
  gem "derailed_benchmarks"
  gem "memory_profiler", require: false
end

group :development do
  gem "flamegraph"
  gem "guard-rspec", require: false
  gem "listen"
  gem "rails-erd"
  gem "spring-commands-rspec"
  gem "spring", "3.1.1"
  gem "web-console", ">= 3.3.0"
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
