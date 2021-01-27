require "tasks/scripts/move_user_recorded_data_to_registration_facility"
require "tasks/scripts/discard_invalid_appointments"

namespace :data_fixes do
  desc "Move all data recorded by a user from a source facility to a destination facility"
  task :move_user_data_from_source_to_destination_facility, [:user_id, :source_facility_id, :destination_facility_id] => :environment do |_t, args|
    user = User.find(args.user_id)
    source_facility = Facility.find(args.source_facility_id)
    destination_facility = Facility.find(args.destination_facility_id)
    service = MoveUserRecordedDataToRegistrationFacility.new(user, source_facility, destination_facility)
    patient_count = service.fix_patient_data
    bp_count = service.fix_blood_pressure_data
    bs_count = service.fix_blood_sugar_data
    appointment_count = service.fix_appointment_data
    prescription_drug_count = service.fix_prescription_drug_data
    puts "[DATA FIXED]"\
         "user: #{user.full_name}, source: #{source_facility.name}, destination: #{destination_facility.name}, "\
         "patients: #{patient_count}, BPs: #{bp_count}, blood sugars: #{bs_count}, "\
         "appointments: #{appointment_count}, prescriptions: #{prescription_drug_count}"
  end

  desc "Clean up invalid scheduled appointments (multiple scheduled appointments for a patient)"
  task :discard_invalid_scheduled_appointments, [:dry_run] => :environment do |_t, args|
    dry_run =
      args.dry_run == "true"

    puts "This is a dry run" if dry_run

    patients_ids = Appointment.where(status: "scheduled").group(:patient_id).count.select { |_k, v| v > 1 }.keys

    Patient.with_discarded.where(id: patients_ids).each do |patient|
      DiscardInvalidAppointments.call(patient: patient, dry_run: dry_run)
    end
  end
end
