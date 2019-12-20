require 'tasks/scripts/soft_delete_duplicate_patients'

desc 'Soft delete patients and their associated records. The task takes a csv file with the duplicate patients marked as `DELETE`'
task :soft_delete_duplicate_patients, [:duplicate_patients_line_list]  => :environment do |_t, args|

  duplicate_patients_line_list_csv = args[:duplicate_patients_line_list]

  abort 'Requires a valid file path.' unless duplicate_patients_line_list_csv.present?
  abort 'Requires a valid file path.' unless File.file?(duplicate_patients_line_list_csv)

  patients = SoftDeleteDuplicatePatients.parse(duplicate_patients_line_list_csv)
  # call the script to parse
  # call the script with parsed results to do the deleting
end