ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = [
   "--exclude-table=simple_reporting.*_[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]", # 8-digit date (e.g. reporting_patient_states_20180101)
  "--exclude-table=simple_reporting.*_[0-9][0-9][0-9][0-9][0-9][0-9][0-9]" # 7-digit truncated (e.g. long table name + _2018010)
]
