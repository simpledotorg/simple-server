source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.1.6.2'
gem 'pg', '>= 0.18', '< 2.0'
gem 'passenger'
gem 'sassc-rails'
gem 'uglifier', '>= 1.3.0'
gem 'jbuilder', '~> 2.5'
gem 'pry-rails'
gem 'sentry-raven'
gem 'dotenv-rails'
gem 'rswag', '~> 1.6.0'
gem 'rspec-rails', '~> 3.7'
gem 'newrelic_rpm'
gem 'bcrypt', '~> 3.1', '>= 3.1.11'
gem 'devise', '~> 4.7.1'
gem 'devise_invitable', '~> 1.7.0'
gem 'twilio-ruby', '~> 5.10', '>= 5.10.3'
gem 'pundit'
gem 'bootstrap', '~> 4.3.1'
gem 'jquery-rails'
gem 'bootstrap_form', '>= 4.1.0'
gem 'groupdate'
gem 'data-anonymization', require: false
gem 'uuidtools', require: false
gem 'discard', '~> 1.0'
gem 'friendly_id', '~> 5.2.4'
gem 'kaminari'
gem 'phonelib'
gem 'http'
gem 'sidekiq'
gem "sidekiq-throttled"
gem 'connection_pool'
gem 'whenever', require: false
gem 'redis'
gem 'redis-rails'
gem 'activerecord-import'
gem "roo", "~> 2.8.0"
gem 'wkhtmltoimage-binary'
gem 'imgkit'
gem 'scenic'
gem 'factory_bot_rails', require: false
gem 'faker', require: false
gem 'timecop', '~> 0.9.0', require: false

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'factory_bot_rails', require: true
  gem 'shoulda-matchers', '~> 3.1'
  gem 'faker', require: true
  gem 'timecop', '~> 0.9.0', require: true
  gem 'capistrano', '~> 3.10'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'capistrano-passenger'
  gem 'capistrano-rails-console', require: false
  gem 'capistrano-sidekiq', require: false
  gem 'capistrano-db-tasks', require: false
  gem 'parallel_tests', group: [:development, :test]
  gem 'rails-controller-testing'
  gem 'rb-readline'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'rails-erd'
end

group :test do
  gem 'capybara'
  gem 'simplecov', require: false
  gem 'launchy'
  gem 'webmock'
  gem 'fakeredis', require:  false
  gem 'generator_spec'
  gem 'webdriver'
  # gem 'rspec-sidekiq'
end

gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
