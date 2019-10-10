namespace :data_migration do
  desc "Create master users for admins"
  task create_master_users_for_admins: :environment do
    Admin.all.each do |admin|
      master_user_id = UUIDTools::UUID.md5_create(
        UUIDTools::UUID_DNS_NAMESPACE,
        { email: admin.email }.to_s
      ).to_s

      master_user_full_name = admin.email.split('@').first

      next if User.find_by(id: master_user_id).present?
      admin.transaction do
        admin_attributes = admin.attributes.with_indifferent_access

        master_user = User.create(
          id: master_user_id,
          full_name: master_user_full_name,
          sync_approval_status: 'denied',
          sync_approval_status_reason: 'User is an admin',
          device_created_at: admin.created_at,
          device_updated_at: admin.updated_at,
          created_at: admin.created_at,
          updated_at: admin.updated_at,
          deleted_at: admin.deleted_at,
        )

        email_authentication = EmailAuthentication.new(admin_attributes.except(:id, :role))

        email_authentication.save(validate: false)

        master_user.user_authentications.create(
          authenticatable: email_authentication
        )
      end
    end
  end

  desc "Fix null invited_by for email authentications when migrating from admins"
  task fix_invited_by_for_email_authentications: :environment do
    EmailAuthentication.all.each do |email_authentication|
      email_authentication.transaction do
        admin = Admin.find_by(email: email_authentication.email)
        invited_by = EmailAuthentication.find_by(email: admin.invited_by.email)

        email_authentication.invited_by = invited_by.master_user
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
    batch_size = ENV['BACKFILL_ENCOUNTERS_FOR_BPS_BATCH_SIZE'].to_i || 1000
    timezone_offset = 19800 # For 'Asia/Kolkata'

    #migrate all blood_pressures in batches
    BloodPressure.in_batches(of: batch_size) do |batch|
      batch.map do |blood_pressure|
        encountered_on = Encounter.generate_encountered_on(blood_pressure.recorded_at, timezone_offset)

        encounter_merge_params = {
          id: Encounter.generate_id(blood_pressure.facility.id, blood_pressure.patient.id, encountered_on),
          patient_id: blood_pressure.patient.id,
          device_created_at: blood_pressure.device_created_at,
          device_updated_at: blood_pressure.device_updated_at,
          encountered_on: encountered_on,
          timezone_offset: timezone_offset,
          observations: {
            blood_pressures: [blood_pressure.attributes.except(:created_at, :updated_at)],
          }
        }.with_indifferent_access

        MergeEncounterService.new(encounter_merge_params, blood_pressure.facility, timezone_offset).merge
      end
    end

    # migrate all patients that have no blood_pressures
    Patient.includes(:blood_pressures).select { |p| p.blood_pressures.blank? }.each do |patient|
      encountered_on = Encounter.generate_encountered_on(patient.recorded_at, timezone_offset)

      encounter_merge_params = {
        id: Encounter.generate_id(patient.registration_facility.id, patient.id, encountered_on),
        patient_id: patient.id,
        device_created_at: patient.device_created_at,
        device_updated_at: patient.device_updated_at,
        encountered_on: encountered_on,
        timezone_offset: timezone_offset,
        observations: {
          blood_pressures: []
        }
      }.with_indifferent_access

      MergeEncounterService.new(encounter_merge_params, patient.registration_facility, timezone_offset).merge
    end
  end
end

