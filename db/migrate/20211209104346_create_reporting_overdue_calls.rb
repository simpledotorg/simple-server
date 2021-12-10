class CreateReportingOverdueCalls < ActiveRecord::Migration[5.2]
  def change
    create_view :reporting_overdue_calls, materialized: true
    add_index :reporting_overdue_calls, [:month_date, :patient_id], name: :overdue_calls_month_date_patient_id, unique: true
  end
end
