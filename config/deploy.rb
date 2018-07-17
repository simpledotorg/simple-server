# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :application, "simple-server"
set :repo_url, "https://github.com/simpledotorg/simple-server.git"
set :deploy_to, -> { "/home/deploy/apps/#{fetch(:application)}" }
set :rbenv_ruby, '2.5.1'
set :rails_env, 'production'

if ENV['DEPLOY_BRANCH']
  set :branch, ENV['DEPLOY_BRANCH']
else
  ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
end

append :linked_files, ".env.production"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"

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
end
