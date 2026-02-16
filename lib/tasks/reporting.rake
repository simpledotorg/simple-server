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

  desc "Do a refresh of said materialized views"
  task :initial_materialized_view_refresh, [:views] => :environment do |_, args|
    # Default list
    default_views = %w[
      latest_blood_pressures_per_patient_per_months
      latest_blood_pressures_per_patient_per_quarters
      latest_blood_pressures_per_patients
      blood_pressures_per_facility_per_days
      materialized_patient_summaries
      reporting_patient_blood_pressures
      reporting_patient_blood_sugars
      reporting_overdue_calls
      reporting_patient_visits
      reporting_prescriptions
      reporting_patient_follow_ups
      reporting_facility_appointment_scheduled_days
      reporting_facility_states
      reporting_facility_daily_follow_ups_and_registrations
    ].freeze
    views_to_refresh =
      if args[:views].present?
        # Expecting a comma-separated list: "view1,view2"
        [args[:views], *args.extras].map(&:strip)
      else
        default_views
      end
    views_to_refresh.each do |view_name|
      puts "Refreshing materialized view: #{view_name} "
      ActiveRecord::Base.connection.exec_query("REFRESH MATERIALIZED VIEW #{view_name}")
    end
  end

  desc "Refresh a partitoned table for given months"
  task :refresh_partitioned_table, [:table_name, :start_date, :end_date] => :environment do |_, args|
    unless args[:table_name].present? && args[:start_date].present? && args[:end_date].present?
      puts "ERROR: table_name, start_date and end_date are required."
      puts "Usage: rake reporting:refresh_partitioned_table['reporting_patient_states', '2024-01-01' ,'2024-02-01']"
      exit 1
    end

    table_name = args[:table_name]
    start_date = Date.parse(args[:start_date]).beginning_of_month
    end_date = Date.parse(args[:end_date]).beginning_of_month
    months = []
    current = start_date
    while current <= end_date
      months << current.strftime("%Y-%m-%d")
      current = current.next_month
    end
    months.each do |month|
      puts "Refreshing partitioned table: #{table_name} for month: #{month}"
      ActiveRecord::Base.connection.exec_query("CALL simple_reporting.add_shard_to_table('#{month}', '#{table_name}')")
    end
  end
end
