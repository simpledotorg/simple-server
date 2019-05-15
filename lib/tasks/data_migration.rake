namespace :data_migration do
  desc "Associate all facility groups in an organization's to a protocol"
  task :associate_protocol_to_organization_facility_groups, [:organization_id, :protocol_id] => :environment do |_t, args|
    organization = Organization.find(args.organization_id)
    protocol = Protocol.find(args.protocol_id)
    puts "Associating organization #{organization.name} to protocol #{protocol.name}"
    puts "Associating protocol for #{organization.facility_groups.count} facility groups"
    organization.facility_groups.update(protocol: protocol)
  end

  desc "Update 'appointment_type' for existing appointments to 'manual'"
  task set_appointment_type_to_manual_for_existing_appointments: :environment do
    appointments = Appointment.where(appointment_type: nil)

    number_of_appointments_marked_manual = 0
    appointments.each do |app|
      puts "Marking appointment #{app.id} as 'manual'"
      app.update_column(:appointment_type, Appointment.appointment_types[:manual])
      number_of_appointments_marked_manual += 1
    end

    puts "Total number of appointments marked as 'manual' = #{number_of_appointments_marked_manual}"
  end

  desc "Create automatic appointment for defaulters so that they show up in the Overdue List"
  task create_automatic_appointment_for_defaulters: :environment do
    last_bp_older_than_one_month = ->(p) { p.latest_blood_pressure.blank? || p.latest_blood_pressure.device_created_at < 1.month.ago }

    patient_is_hypertensive = ->(p) { p.latest_blood_pressure.present? && p.latest_blood_pressure.hypertensive? }

    patient_has_cardio_vascular_history = ->(p) { p.medical_history.present? && p.medical_history.indicates_risk? }

    defaulters = Patient.select do |p|
      p.appointments.count == 0 &&
        last_bp_older_than_one_month.call(p) &&
        (patient_is_hypertensive.call(p) || patient_has_cardio_vascular_history.call(p) || p.prescription_drugs.present?)
    end

    puts "Found #{defaulters.count} defaulters"

    if defaulters.blank? || defaulters.empty?
      abort("No defaulters found. Aborting task.")
    end

    puts "Processing #{defaulters.count} defaulters..."

    processed_defaulters_count = 0
    unprocessed_or_errored_defaulters_count = 0

    defaulters.each do |defaulter|
      if defaulter.latest_blood_pressure.blank?
        puts "Failed to find latest Blood Pressure reading for defaulter #{defaulter.id}. Skipping patient..."
        unprocessed_or_errored_defaulters_count += 1
        next
      end

      latest_bp_facility_id = defaulter.latest_blood_pressure.facility_id
      appointment_creation_time = defaulter.latest_blood_pressure.device_created_at
      appointment_scheduled_date = appointment_creation_time + 1.month

      begin
        automatic_appointment =
          Appointment.create(patient_id: defaulter.id, facility_id: latest_bp_facility_id,
                             device_created_at: appointment_creation_time, device_updated_at: appointment_creation_time, status: 'scheduled', scheduled_date: appointment_scheduled_date, appointment_type: Appointment.appointment_types[:automatic])

        if automatic_appointment.errors.present?
          puts "Error(s) while creating automatic appointment for patient #{defaulter.id}: #{automatic_appointment.errors.messages}"
          unprocessed_or_errored_defaulters_count += 1
          next
        end

        processed_defaulters_count += 1

        puts "Created automatic appointment #{automatic_appointment.id} for defaulter #{defaulter.id}"
      rescue StandardError => err
        puts "Failed to create automatic appointment for defaulter #{defaulter.id}. Reason: #{err}"
        unprocessed_or_errored_defaulters_count += 1
      end
    end

    puts "Number of defaulters processed (automatic appointment created) = #{processed_defaulters_count}"
    puts "Number of unprocessed/errored defaulters = #{unprocessed_or_errored_defaulters_count}"
  end

  desc "Set default 'recorded_at' for existing records"
  task set_default_recorded_at_for_existing_records: :environment do
    # For BloodPressure records,
    # we default to the device_created_at
    bps_without_recorded_at = BloodPressure.where(recorded_at: nil)

    bps_without_recorded_at.each do |record|
        record.update_column(:recorded_at, record.device_created_at)
    end

    puts "Total number of BloodPressure records updated = #{bps_without_recorded_at.size}"

    # Patients' recorded_at is set to their earliest
    # BP's device_created_at if older than theirs
    patients = Patient.where(recorded_at: nil)

    patients.each do |patient|
      earliest_blood_pressure = patient.blood_pressures.order(device_created_at: :asc).first
      earlier_date = [earliest_blood_pressure.device_created_at, patient.device_created_at].min
      patient.update_column(:recorded_at, earlier_date)
    end

    puts "Total number of Patient records updated = #{patients.size}"

  desc 'Move all the user phone numbers from the call logs to a de-normalized caller_phone_number field'
  task de_normalize_user_phone_numbers_in_call_logs: :environment  do
    CallLog.all.each do |call_log|
      call_log.caller_phone_number = call_log.user.phone_number
      call_log.save!
    end
  end
end
