require 'tasks/data_clean_up/move_user_recorded_data_to_registration_facility'

namespace :data_fixes do
  desc 'Set all appointments with a newer blood pressure reading than the created_at date to "visited"'
  task :fix_impossible_overdue_appointments, [:user_id] => :environment do |_t, args|
    user = User.find(args.user_id)
    patients_created_by_user = Patient.where(registration_user_id: user.id)

    updated_appointments = 0
    appointments_with_no_create_log = 0
    patients_created_by_user.each do |patient|
      latest_blood_pressure = patient.blood_pressures.order(device_created_at: :desc).first

      if latest_blood_pressure.blank?
        puts "No blood pressure found - skipping patient #{patient.id}"
        next
      end

      all_appointments =
        patient.appointments.where(status: 'scheduled')
          .select do |app|
          create_audit_log = app.audit_logs.find_by(action: 'create');
          if create_audit_log.blank?
            puts "Appointment #{app.id} is missing `create` audit logs - filtering out"
            appointments_with_no_create_log += 1
            false
          else
            create_audit_log.user == user
          end
        end

      all_appointments.each do |app|
        if app.scheduled_date < latest_blood_pressure.device_created_at
          puts "Marking status for appointment #{app.id} as visited\n"
          app.update(status: 'visited')
          updated_appointments += 1
        end
      end
    end
    puts "Total number of updated appointments = #{updated_appointments}"
    puts "Total number of appointments missing `create` audit logs = #{appointments_with_no_create_log}"
  end

  desc "Move all data recorded by a user from a specified facility to their registration facility"
  task :move_user_data_from_a_facility_to_their_registration_facility, [:user_id, :facility_id] => :environment do |_t, args|
    user = User.find(args.user_id)
    wrong_facility = Facility.find(args.facility_id)

    service = MoveUserRecordedDataToRegistrationFacility.new(user, wrong_facility)
    patient_count = service.fix_patient_data
    bp_count = service.fix_blood_pressure_data
    appointment_count = service.fix_appointment_data
    prescription_drug_count = service.fix_prescription_drug_data
    puts "#{user.full_name},#{wrong_facility.name},#{patient_count},#{bp_count},#{appointment_count},#{prescription_drug_count}"
  end
end
