namespace :impossible_overdue_appointments do
  desc 'Set all appointments with a newer blood pressure reading than the created_at date to "visited"'
  task :fix_impossible_overdue_appointments, [:user_id] => :environment do |_t, args|
    card_reader_bot = User.find(args.user_id)
    patients_created_by_bot = Patient.where(registration_user_id: card_reader_bot.id)

    updated_appointments = 0
    appointments_with_no_create_log = 0
    patients_created_by_bot.each do |patient|
      puts "Processing patient #{patient.id}"

      latest_blood_pressure = patient.blood_pressures.order(device_created_at: :desc).first

      if latest_blood_pressure.blank?
        puts "No blood pressure found - skipping patient #{patient.id}"
        puts
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
            app.audit_logs.find_by(action: 'create').user == card_reader_bot
          end
        end

      all_appointments.each do |app|
        if app.scheduled_date < latest_blood_pressure.device_created_at
          puts "Marking status for appointment #{app.id} as visited\n"
          app.status = 'visited'
          app.save
          updated_appointments += 1
        end
      end
      puts "Finished processing patient #{patient.id}"
      puts
    end
    puts "Total number of updated appointments = #{updated_appointments}"
    puts "Total number of appointments missing `create` audit logs = #{appointments_with_no_create_log}"
  end
end
