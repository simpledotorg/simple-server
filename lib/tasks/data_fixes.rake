require 'tasks/scripts/move_user_recorded_data_to_registration_facility'

namespace :data_fixes do
  desc 'Move all data recorded by a user from a source facility to a destination facility'
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

  desc 'Fix everything'
  task :port_duplicated_patient_data => :environment do
    #* Import BD data locally
    #* Identify the dupe patients (code)
    #* For the dupe patients, identify the measurements - Appointments, BPs, MHs, Medications, Passports, NIDs, phone_numbers, addresses, patient, Observations, encounters, blood_sugars (code)
    #* Look up the real patients for the dupes
    #                              * Look up the real patients separately in this order of matchability
    #                              * matcher => name, age, address, phone_numbers
    #                              * matcher => name, age, address
    #                              * matcher => name, age
    #                              * Port the measurements from dupe patient data to real patient data
    #
    #                              MHs
    #
    #                              Syncs with user
    #
    #                              * BloodPressure
    #                              * BloodSugar
    #                              * Encounters
    #                              * Observations
    #                              * Appointments
    #                              * Prescription Drug
    #                              * MedicalHistory
    #
    #                              Syncs w/o user
    #
    #                              * Patient
    #                              * Address (patient)  (confirm with mobile team if phone number edit is in place)
    #                              * BusinessIdentifier (confirm with mobile team if phone number edit is in place)
    #                              * PatientPhoneNumber (confirm with mobile team if phone number edit is in place)
    #

    user_id = '2b469d02-f746-4550-bb91-6651143ca8cc'
    duplicate_patients = User.find(user_id).registered_patients

    matched = 0
    unmatched = 0

    duplicate_patients.each do |p|
      first_match_attempt = Patient.where(age: p.age, full_name: p.full_name).where.not(id: p.id)
      (matched += 1) && next if first_match_attempt.count == 1

      address_attrs = p.address.slice(:street_address, :village_or_colony, :district, :state, :country, :pin)
      second_match_attempt = Patient
                               .joins(:address)
                               .where(age: p.age, full_name: p.full_name)
                               .where.not(id: p.id)
                               .where(addresses: address_attrs)
      (matched += 1) && next if second_match_attempt.count == 1

      third_match_attempt = second_match_attempt.select do |patient|
        p.latest_phone_number && (patient.latest_phone_number == p.latest_phone_number)
      end
      (matched += 1) && next if third_match_attempt.count == 1

      unmatched += 1
    end

    puts "Matched patients: #{matched}"
    puts "Unmatched patients: #{unmatched}"
  end
end
