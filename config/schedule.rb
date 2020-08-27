require "tzinfo"
require File.expand_path("../config/environment", __dir__)

set :output, "/home/deploy/apps/simple-server/shared/log/cron.log"

env :PATH, ENV["PATH"]
DEFAULT_CRON_TIME_ZONE = "Asia/Kolkata"

def local(time)
  TZInfo::Timezone.get(Rails.application.config.country[:time_zone] || DEFAULT_CRON_TIME_ZONE)
    .local_to_utc(Time.parse(time))
end

every :day, at: local("11:00 pm").utc, roles: [:cron] do
  rake "appointment_notification:three_days_after_missed_visit"
end

every :day, at: local("12:00 am"), roles: [:whitelist_phone_numbers] do
  rake "exotel_tasks:whitelist_patient_phone_numbers"
end

every :week, at: local("01:00 am"), roles: [:whitelist_phone_numbers] do
  rake "exotel_tasks:update_all_patients_phone_number_details"
end

# Disable cache warming while we inspect the outage on 2020-08-27
#
# every :day, at: local("02:00 am"), roles: [:cron] do
#   runner "Reports::RegionCacheWarmer.call"
# end

every 3.hours, roles: [:cron] do
  rake "refresh_materialized_db_views"
end

every :month, at: local("02:00 am"), roles: [:seed_data] do
  rake "db:purge_users_data"
  rake "db:seed_users_data"
end
