require 'tzinfo'

set :output, "/home/deploy/apps/simple-server/shared/log/cron.log"

def local(time)
  TZInfo::Timezone.get("Asia/Kolkata").local_to_utc(Time.parse(time))
end

every :day, at: local('1:00 am').utc do
  runner "WarmUpAnalyticsCacheJob.perform_later"
end

every :month, at: local('1:00 am').utc do
  runner "WarmUpQuarterlyAnalyticsCacheJob.perform_later"
end