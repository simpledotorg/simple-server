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
end
