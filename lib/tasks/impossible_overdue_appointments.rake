namespace :impossible_overdue_appointments do
  desc 'Set all appointments with a newer blood pressure reading than the created_at date to "visited"'
  task :fix_impossible_overdue_appointments, [:user_id] => :environment do |_t, args|
    card_reader_bot = User.find(args.user_id)
    patients_created_by_bot = Patient.where(registration_user_id: card_reader_bot.id)

    updated_appointments = 0
    patients_created_by_bot.each do |patient|
      puts "Processing patient #{patient.id}"

      latest_blood_pressure = patient.blood_pressures.order(device_created_at: :desc).first
      latest_scheduled_appointment = patient.appointments.where(status: 'scheduled').order(device_created_at: :desc).first

      if latest_scheduled_appointment.blank? ||
        latest_blood_pressure.blank? ||
        latest_scheduled_appointment.audit_logs.blank?
        puts "No scheduled appointment(s) or blood pressure or audit log found - skipping patient #{patient.id}"
        puts
        next
      end

      create_audit_log = latest_scheduled_appointment.audit_logs.where(action: 'create').first

      if create_audit_log.blank?
        puts "No audit log found for the latest scheduled appointment - skipping patient #{patient.id}"
        puts
        next
      end

      if latest_scheduled_appointment.scheduled_date < latest_blood_pressure.device_created_at
        all_appointments =
          patient.appointments.where(status: 'scheduled')
            .select { |app| app.audit_logs.where(action: 'create').first.user == card_reader_bot }

        all_appointments.each do |app|
          puts "Marking status for appointment #{app.id} as visited\n"
          app.status = 'visited'
          app.save
          updated_appointments += 1
        end
        puts "Finished processing patient #{patient.id}"
        puts
      else
        puts "Appointment not created by Card Reader Bot or no newer BP reading - Skipping patient #{patient.id}"
        puts
      end
    end

    puts "Total number of updated appointments = #{updated_appointments}"
  end
end