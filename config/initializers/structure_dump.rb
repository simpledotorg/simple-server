ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = [
  "--exclude-table=simple_reporting.reporting_patient_states_*",
  "--exclude-table=simple_reporting.reporting_facility_monthly_follow_ups_and_registrations_*"
]
