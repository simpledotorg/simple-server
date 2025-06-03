# frozen_string_literal: true

namespace :reporting do
  desc "Do a full refresh of the partitioned reporting table"
  task full_partitioned_refresh: :environment do
    reporting_tables = %w[
      Reports::PatientState
    ].freeze

    reporting_tables.each do |reporting_table|
      ActiveRecord::Base.connection.exec_query(
        "TRUNCATE TABLE simple_reporting.#{reporting_table.constantize.table_name}"
      )
      Reports::Month.order(:month_date).select(:month_date).each do |reporting_month|
        reporting_table.constantize.partitioned_refresh(reporting_month.month_date)
      end
    end
  end
end
