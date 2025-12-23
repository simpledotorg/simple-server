# frozen_string_literal: true

namespace :reporting do
  desc "Do a full refresh of the partitioned reporting table"
  task :full_partitioned_refresh, [:table_name] => :environment do |t, args|
    unless args[:table_name].present?
      puts "ERROR: table_name is required."
      puts "Usage: rake reporting:full_partitioned_refresh[reporting_patient_states]"
      exit 1
    end

    reporting_table = args[:table_name]
    Reports::Month.order(:month_date).select(:month_date).each_with_index do |reporting_month, index|
      RefreshReportingPartitionedTableJob.set(wait_until: Time.now + (index * 45).minutes).perform_async(reporting_month.month_date.to_s, reporting_table)
    end
  end
end
