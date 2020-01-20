namespace :data_migration do
  desc "Create master users for admins"
  task create_master_users_for_admins: :environment do
    require 'tasks/scripts/create_master_user'

    Admin.all.each do |admin|
      begin
        CreateMasterUser.from_admin(admin)
      rescue StandardError => e
        puts "Skipping #{admin.email}: #{e.message}"
      end
    end
  end

  desc "Fix null invited_by for email authentications when migrating from email_authentications"
  task fix_invited_by_for_email_authentications: :environment do
    EmailAuthentication.all.each do |email_authentication|
      email_authentication.transaction do
        admin = Admin.find_by(email: email_authentication.email)
        next unless admin.present? && admin.invited_by.present?
        invited_by = EmailAuthentication.find_by(email: admin.invited_by.email)

        email_authentication.invited_by = invited_by.user
        email_authentication.save
      end
    end
  end

  desc 'Move all the user phone numbers from the call logs to a de-normalized caller_phone_number field'
  task de_normalize_user_phone_numbers_in_call_logs: :environment do
    CallLog.all.each do |call_log|
      call_log.caller_phone_number = call_log.user.phone_number
      call_log.save!
    end
  end

  desc 'Export audit logs to files'
  task :export_audit_logs_to_files, [:from_date, :to_date] => :environment do |_t, args|
    from_date = Date.parse(args.from_date)
    to_date = Date.parse(args.to_date)
    (from_date..to_date).each do |date|
      ExportAuditLogsWorker.perform_async(date)
    end
  end

  desc 'Backfill user_ids for a model from audit_logs (Appointment, PrescriptionDrug and MedicalHistory)'
  task :backfill_user_ids_for_model, [:model] => :environment do |_t, args|
    model = args.model
    batch_size = ENV.fetch('BACKFILL_USER_ID_FROM_AUDIT_LOGS_BATCH_SIZE').to_i
    AuditLog.where(auditable_type: model, action: 'create').in_batches(of: batch_size) do |batch|
      puts "Fetched #{batch_size} records for #{model}"
      model_log_ids = batch.map do |model_instance|
        { id: model_instance.auditable_id,
          user_id: model_instance.user_id }
      end
      puts "Enqueueing user id backfill job for #{batch_size} #{model} records"
      UpdateUserIdsFromAuditLogsWorker.perform_async(model.constantize, model_log_ids)
    end
  end

  desc 'Set reminder_consent to granted for all patients'
  task grant_reminder_consent_for_all_patients: :environment do
    Patient.update_all(reminder_consent: Patient.reminder_consents[:granted])
  end

  desc 'Backport all BloodPressures to have Encounters and appropriate Observations'
  task :add_encounters_to_existing_blood_pressures => :environment do |_t, _args|
    batch_size = (ENV['BACKFILL_ENCOUNTERS_FOR_BPS_BATCH_SIZE'] || 1000).to_i
    timezone_offset = ENV['BACKFILL_ENCOUNTERS_FOR_BPS_TIMEZONE_OFFSET'].to_i # For 'Asia/Kolkata'

    # migrate all blood_pressures in batches
    BloodPressure
      .left_outer_joins(:encounter, :facility, :user)
      .where(encounters: { id: nil })
      .where.not(facilities: { id: nil }, users: { id: nil })
      .in_batches(of: batch_size) do |batch|
        CreateMissingEncountersJob.perform_async(batch.map(&:id), timezone_offset)
      end
  end

  desc 'Backfill creation_facility for all existing Appointments'
  task backfill_creation_facility_in_appointments: :environment do
    Appointment.where(creation_facility_id: nil).in_batches.update_all('creation_facility_id = facility_id')
  end

  desc 'Make all occurrences of the SMS Reminder Bot User nil'
  task remove_bot_user_usages: :environment do
    Communication.where(user: ENV['APPOINTMENT_NOTIFICATION_BOT_USER_UUID']).update_all(user_id: nil)
  end

  desc "Add facility sizes based on facility type"
  task add_facility_sizes: :environment do
    size_map = {
      "CH" => :large,
      "DH" => :large,
      "Hospital" => :large,
      "RH" => :large,
      "SDH" => :large,

      "CHC" => :medium,

      "MPHC" => :small,
      "PHC" => :small,
      "SAD" => :small,
      "Standalone" => :small,
      "UHC" => :small,
      "UPHC" => :small,
      "USAD" => :small,

      "HWC" => :community,
      "Village" => :community
    }

    size_map.each do |facility_type, facility_size|
      Facility.where(facility_type: facility_type, facility_size: nil).each do |facility|
        puts "Updating #{facility.name}: #{facility.facility_type} --> #{facility_size}"
        facility.update(facility_size: facility_size)
      end
    end
  end

  desc 'Assign organization to users from registration facility'
  task assign_organization_to_users: :environment do
    User.where(organization: nil)
      .select { |u| u.registration_facility.present? }
      .each do |user|
      user.organization = user.registration_facility.organization
      user.save!
    end
  end
end
