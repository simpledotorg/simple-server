# frozen_string_literal: true

set :sidekiq_service_name, "sidekiq"

namespace :sidekiq do
  desc "Restart sidekiq service"
  task :restart do
    on roles :sidekiq do
      execute :systemctl, :restart, fetch(:sidekiq_service_name), "--user"
    end
  end

  desc "Quiet sidekiq (stop fetching new tasks from Redis)"
  task :quiet do
    on roles :sidekiq do
      execute :systemctl, "--user", "kill -s TSTP", fetch(:sidekiq_service_name)
    end
  end

  desc "Stop sidekiq (graceful shutdown within timeout, put unfinished tasks back to Redis)"
  task :stop do
    on roles :sidekiq do
      execute :systemctl, "--user", "stop", fetch(:sidekiq_service_name)
    end
  end

  task :add_default_hooks do
    after "deploy:starting", "sidekiq:quiet"
    after "deploy:updated", "sidekiq:stop"
    after "deploy:published", "sidekiq:restart"
    after "deploy:failed", "sidekiq:restart"
  end
end
