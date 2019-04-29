require 'tzinfo'

set :output, "/home/deploy/apps/simple-server/shared/log/cron.log"

DEFAULT_CRON_TIME_ZONE = 'Asia/Kolkata'

def local(time)
  TZInfo::Timezone.get(DEFAULT_CRON_TIME_ZONE).local_to_utc(Time.parse(time))
end

every :day, at: local('1:00 am').utc do
  runner "WarmUpAnalyticsCacheJob.perform_later"
end

every 5.minutes do
  rake 'sms_reminder:three_days_after_missed_visit'
end

every :month, at: local('1:00 am').utc do
  runner "WarmUpQuarterlyAnalyticsCacheJob.perform_later"
end
