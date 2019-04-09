# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "/home/deploy/apps/simple-server/shared/logs/cron.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every :day, at: ['1:00 am'] do
  runner "WarmUpAnalyticsCacheJob.perform_later"
end

every :month, at: ['1:00 am'] do
  runner "WarmUpQuarterlyAnalyticsCacheJob.perform_later"
end