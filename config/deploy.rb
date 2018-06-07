# config valid for current version and patch releases of Capistrano
lock "~> 3.11.0"

set :application, "redapp-server"
set :repo_url, "https://github.com/resolvetosavelives/redapp-server.git"
set :deploy_to, "/home/ubuntu/apps"
set :rbenv_ruby, '2.3.4'
set :rails_env, 'production'

ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

append :linked_files, ".env.production"
append :linked_dirs, "log", "tmp/pids", "tmp/cache", "tmp/sockets", "public/system"
