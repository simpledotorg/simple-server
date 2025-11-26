# frozen_string_literal: true

namespace :reporting do
  desc "Do a full refresh of the partitioned reporting table"
  task full_partitioned_refresh: :environment do
    reporting_tables = %w[
      Reports::PatientState
    ].freeze

    reporting_tables.each do |reporting_table|
      klass = reporting_table.constantize
      ActiveRecord::Base.connection.exec_query(
        "TRUNCATE TABLE simple_reporting.#{klass.table_name}"
      )
      Reports::Month.order(:month_date).select(:month_date).each_with_index do |reporting_month, index|
        RefreshReportingPartitionedTableJob.set(wait_until: Time.now + (index * 45).minutes).perform_async(reporting_month.month_date.to_s, klass.table_name)
      end
    end
  end

  desc "Do a refresh of said materialized views"
  task :initial_materialized_view_refresh, [:views] => :environment do |_, args|
    # Default list
    default_views = %w[
      latest_blood_pressures_per_patient_per_months
      latest_blood_pressures_per_patient_per_quarters
      latest_blood_pressures_per_patients
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
end
