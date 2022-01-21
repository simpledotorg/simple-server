# config valid for current version and patch releases of Capistrano
lock "~> 3.16.0"

set :application, "simple-server"
set :repo_url, "https://github.com/simpledotorg/simple-server.git"
set :deploy_to, -> { "/home/deploy/apps/#{fetch(:application)}" }
set :rbenv_ruby, File.read(".ruby-version").strip

set :default_env, {
  path: "/home/deploy/.rbenv/plugins/ruby-build/bin:/home/deploy/.rbenv/shims:/home/deploy/.rbenv/bin:$PATH",
  rbenv_root: "/home/deploy/.rbenv"
}

set :rails_env, "production"
set :branch, ENV["BRANCH"] || "master"

set :bundler_path, "/home/deploy/.rbenv/shims/bundle"
set :sidekiq_processes, 4

set :db_local_clean, false
set :db_remote_clean, true
set :disallow_pushing, true

set :sentry_api_token, ENV["SENTRY_AUTH_TOKEN"]
set :sentry_organization, "resolve-to-save-lives"
set :sentry_repo, "simpledotorg/simple-server"
# Fire off release notifications to Sentry after successful deploys
before "deploy:starting", "sentry:validate_config"
after "deploy:published", "sentry:notice_deployment"
after "deploy:symlink:linked_dirs", "deploy:fix_bundler_plugin_path"

append :linked_dirs, ".bundle"
append :linked_files, ".env.production"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system", "public/packs", "node_modules"

set :whenever_path, -> { release_path }
set :whenever_roles, [:cron, :whitelist_phone_numbers]
set :enable_confirmation, ENV["CONFIRM"] || "true"
set :envs_for_confirmation_step, ["production", "staging"]

set :passenger_restart_with_sudo, true

Capistrano::DSL.stages.each do |stage|
  # For each stage that requires confirmation load the `deploy:confirmation` task
  # Use the `envs_for_confirmation_step` var to set the appropriate stages
  next unless fetch(:enable_confirmation) == "true"
  after stage, "deploy:confirmation" if fetch(:envs_for_confirmation_step).any? { |env| stage == env }
end
