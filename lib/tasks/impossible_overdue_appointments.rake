namespace :impossible_overdue_appointments do
  desc 'Set all appointments with a newer blood pressure reading than the created_at date to "visited"'
  task :fix_impossible_overdue_appointments, [:card_reader_bot_id] => :environment do |_t, args|
    card_reader_bot = User.find(args.card_reader_bot_id)
    patients_created_by_bot = Patient.where(registration_user_id: card_reader_bot.id)

    patients_created_by_bot.each do |patient|
      puts "Processing patient #{patient.id}"

      latest_blood_pressure = patient.blood_pressures.order(device_created_at: :desc).first
      latest_scheduled_appointment = patient.appointments.where(status: 'scheduled').order(device_created_at: :desc).first

      create_audit_log = latest_scheduled_appointment&.audit_logs&.where(action: 'create')&.first

      if create_audit_log&.user == card_reader_bot && latest_scheduled_appointment.present? && latest_scheduled_appointment.scheduled_date < latest_blood_pressure.device_created_at
        # latest_scheduled_appointment.update(status: 'visited')
        all_appointments =
          patient.appointments.where(status: 'scheduled')
            .select { |app| app&.audit_logs.where(action: 'create').first.user == card_reader_bot }

        all_appointments.each do |app|
          puts "Marking status for appointment #{app.id} as visited"
          puts
        end

        puts "Finished processing patient #{patient.id}"
      else
        puts "Skipping patient #{patient.id}"
        puts
      end
    end
  end
end