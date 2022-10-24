class AddReportingOverdueCallsIndexes < ActiveRecord::Migration[6.1]
  def change
    add_index :reporting_overdue_calls, [:call_result_created_at], name: :index_overdue_calls_call_result_created_at
    add_index :reporting_overdue_calls, [:appointment_facility_region_id], name: :index_overdue_calls_appointment_facility
  end
end
