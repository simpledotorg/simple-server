require 'tzinfo'

set :output, "/home/deploy/apps/simple-server/shared/log/cron.log"

env :PATH, ENV['PATH']
DEFAULT_CRON_TIME_ZONE='Asia/Kolkata'

def local(time)
  TZInfo::Timezone.get(DEFAULT_CRON_TIME_ZONE).local_to_utc(Time.parse(time))
end

every :day, at: local('1:00 am').utc do
  rake 'analytics:warm_up_last_ninety_days'
end

every :day, at: local('2:00 am').utc do
  rake 'appointment_notification:three_days_after_missed_visit'
end

every :month, at: local('1:00 am').utc do
  rake 'analytics:warm_up_last_four_quarters'
end
