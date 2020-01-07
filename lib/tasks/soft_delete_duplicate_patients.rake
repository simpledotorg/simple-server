require 'tasks/scripts/soft_delete_duplicate_patients'

desc 'Soft delete patients and their associated records. The task takes a csv file with the duplicate patients marked as `DELETE`'
task :soft_delete_duplicate_patients, [:duplicate_patients_line_list]  => :environment do |_t, args|
  # bundle exec soft_delete_duplicate_patients[<path_to_duplicate_patients_csv>]

  duplicate_patients_line_list_csv = args[:duplicate_patients_line_list]

  abort 'Requires a valid file path.' unless duplicate_patients_line_list_csv.present?
  abort 'Requires a valid file path.' unless File.file?(duplicate_patients_line_list_csv)

  patient_ids = SoftDeleteDuplicatePatients.parse(duplicate_patients_line_list_csv)
  SoftDeleteDuplicatePatients.discard_patients(patient_ids)
end