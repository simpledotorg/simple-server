# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :application, "simple-server"
set :repo_url, "https://github.com/simpledotorg/simple-server.git"
set :deploy_to, -> { "/home/deploy/apps/#{fetch(:application)}" }
set :rbenv_ruby, "2.5.1"
set :default_env, {
  path: "/home/deploy/.rbenv/plugins/ruby-build/bin:/home/deploy/.rbenv/shims:/home/deploy/.rbenv/bin:$PATH",
  rbenv_root: "/home/deploy/.rbenv"
}
set :rails_env, "production"
set :branch, ENV["BRANCH"] || "master"

# sidekiq configuration
set :sidekiq_roles, :sidekiq
set :sidekiq_processes, 4
set :bundler_path, "/home/deploy/.rbenv/shims/bundle"
set :init_system, :systemd
set :pty, false

set :sidekiq_config, -> { File.join(shared_path, "config", "sidekiq.yml") }

set :db_local_clean, false
set :db_remote_clean, true
set :disallow_pushing, true

append :linked_dirs, ".bundle"
append :linked_files, ".env.production"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

set :whenever_path, -> { release_path }
set :whenever_roles, [:cron, :whitelist_phone_numbers]
set :enable_confirmation, ENV["CONFIRM"] || "true"
set :envs_for_confirmation_step, ["production", "staging"]

set :default_env, {
  path: "/home/deploy/.rbenv/plugins/ruby-build/bin:/home/deploy/.rbenv/shims:/home/deploy/.rbenv/bin:$PATH",
  rbenv_root: "/home/deploy/.rbenv"
}

Capistrano::DSL.stages.each do |stage|
  # For each stage that requires confirmation load the `deploy:confirmation` task
  # Use the `envs_for_confirmation_step` var to set the appropriate stages
  next unless fetch(:enable_confirmation) == "true"
  after stage, "deploy:confirmation" if fetch(:envs_for_confirmation_step).any? { |env| stage == env }
end
