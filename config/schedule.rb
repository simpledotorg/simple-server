require 'tzinfo'

set :output, "/home/deploy/apps/simple-server/shared/log/cron.log"

env :PATH, ENV['PATH']
DEFAULT_CRON_TIME_ZONE = 'Asia/Kolkata'

def local(time)
  TZInfo::Timezone.get(DEFAULT_CRON_TIME_ZONE)
                  .local_to_utc(Time.parse(time))
end

every :day, at: local('11:00 pm').utc, roles: [:cron] do
  rake 'appointment_notification:three_days_after_missed_visit'
end

every :day, at: local('12:00 am'), roles: [:whitelist_phone_numbers] do
  rake 'exotel_tasks:whitelist_patient_phone_numbers'
end

every :week, at: local('01:00 am'), roles: [:whitelist_phone_numbers] do
  rake 'exotel_tasks:update_all_patients_phone_number_details'
end

every :week, at: local('02:00 am'), roles: [:fake_data] do
  rake 'generate:fake_data'
end

every 3.hours, roles: [:cron] do
  rake 'refresh_materialized_db_views'
end
