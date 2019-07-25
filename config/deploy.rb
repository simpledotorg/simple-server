# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :application, "simple-server"
set :repo_url, "https://github.com/simpledotorg/simple-server.git"
set :deploy_to, -> { "/home/deploy/apps/#{fetch(:application)}" }
set :rbenv_ruby, '2.5.1'
set :rails_env, 'production'
set :branch, ENV["BRANCH"] || "master"

# sidekiq configuration
set :sidekiq_roles, :sidekiq
set :sidekiq_processes, 1
set :bundler_path, "/home/deploy/.rbenv/shims/bundle"
set :init_system, :systemd
set :pty, false

set :sidekiq_config, -> { File.join(shared_path, 'config', 'sidekiq.yml') }

set :db_local_clean, true
set :db_remote_clean, true
set :disallow_pushing, true

append :linked_files, ".env.production"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

set :whenever_path, -> { release_path }
set :whenever_roles, [:cron, :whitelist_phone_numbers]

ENVS_FOR_CONFIRMATION_STEP = ["production", "staging"]
namespace :deploy do
  desc 'Runs any rake task, example: cap deploy:rake task=db:seed'
  task rake: [:set_rails_env] do
    on release_roles([:db]) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :rake, ENV['task']
        end
      end
    end
  end

  desc 'Confirm if you really want to execute the task'
  task :confirmation do
    puts <<-WARN

    ===============================================================================

      WARNING: You're about to run tasks on #{ENVS_FOR_CONFIRMATION_STEP.join('/')} server(s)
      Please confirm that all your intentions are kind and friendly.

      READ THIS IF YOU ARE RUNNING A DEPLOY TASK:

      This will deploy `#{fetch(:branch)}` to `#{fetch(:stage)}`. Ensure that:

      * You are deploying the correct branch
      * You are deploying to the correct environment
      * Your application configs are up-to-date
      * Any necessary database/data migrations have been run

    ===============================================================================

    WARN
    ask :value, "Are you sure you want to continue? (Y)"

    if fetch(:value) != 'Y'
      puts "\nDeploy canceled!"
      exit
    end
  end
end

Capistrano::DSL.stages.each do |stage|
  after stage, 'deploy:confirmation' if ENVS_FOR_CONFIRMATION_STEP.any? { |env| stage == env }
end
