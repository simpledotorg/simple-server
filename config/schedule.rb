require 'tzinfo'

set :output, "/home/deploy/apps/simple-server/shared/log/cron.log"

env :PATH, ENV['PATH']
DEFAULT_CRON_TIME_ZONE='Asia/Kolkata'

def local(time)
  TZInfo::Timezone.get(DEFAULT_CRON_TIME_ZONE).local_to_utc(Time.parse(time))
end

every :day, at: local('1:00 am').utc do
  runner "WarmUpAnalyticsCacheJob.perform_later"
end

every :day, at: local('2:00 am').utc do
  rake 'appointment_notification:three_days_after_missed_visit'
end

every :day, at: local('3:00 am').utc do
  rake 'data_migration:set_default_recorded_at_for_existing_patients'
end

every :month, at: local('1:00 am').utc do
  runner "WarmUpQuarterlyAnalyticsCacheJob.perform_later"
end
