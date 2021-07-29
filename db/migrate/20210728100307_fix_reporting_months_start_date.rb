class FixReportingMonthsStartDate < ActiveRecord::Migration[5.2]
  def up
    execute "SET LOCAL TIME ZONE '#{Rails.application.config.country[:time_zone]}'"
    replace_view :reporting_months, version: 3, revert_to_version: 2, materialized: false
  end
end
