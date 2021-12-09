class CreateReportingOverdueCalls < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_overdue_calls, materialized: true
  end
end
