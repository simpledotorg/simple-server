# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"
require "prometheus_exporter/client"

Rails.application.load_tasks

def is_running_migration?
  Rake.application.top_level_tasks.include?("db:migrate")
end

task :after_hook do
  at_exit do
    # Rake tasks often quit before the data is sent to the Prometheus
    # collector.
    # This hook will wait for 10 seconds for the queue to become empty
    # and closing the socket.
    PrometheusExporter::Client.default.stop(wait_timeout_seconds: 10)
  end
end

tasks = Rake.application.tasks
tasks.each do |task|
  next if [Rake::Task["after_hook"]].include?(task)
  task.enhance([:after_hook])
end

Rake::Task["db:schema:load"].enhance [:support_pg_extensions_in_heroku]
