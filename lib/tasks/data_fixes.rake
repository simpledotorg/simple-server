require 'tasks/data_clean_up/move_user_recorded_data_to_registration_facility'

namespace :data_fixes do
  desc "Move all data recorded by a user from a source facility to a destination facility"
  task :move_user_data_from_source_to_destination_facility, [:user_id, :source_facility_id, :destination_facility_id] => :environment do |_t, args|
    user = User.find(args.user_id)
    source_facility = Facility.find(args.source_facility_id)
    destination_facility = Facility.find(args.destination_facility_id)
    service = MoveUserRecordedDataToRegistrationFacility.new(user, source_facility, destination_facility)
    patient_count = service.fix_patient_data
    bp_count = service.fix_blood_pressure_data
    appointment_count = service.fix_appointment_data
    prescription_drug_count = service.fix_prescription_drug_data
    puts "[DATA FIXED] #{user.full_name},#{source_facility.name},#{destination_facility.name},#{patient_count},#{bp_count},#{appointment_count},#{prescription_drug_count}"
  end
end
