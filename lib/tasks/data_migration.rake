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

  desc 'Backfill user_ids for a model from audit_logs (Appointment, PrescriptionDrug and MedicalHistory)'
  task :backfill_user_ids_for_model, [:model] => :environment do |_t, args|
    model = args.model
    batch_size = ENV.fetch('BACKFILL_USER_ID_FROM_AUDIT_LOGS_BATCH_SIZE').to_i
    AuditLog.where(auditable_type: model, action: 'create').in_batches(of: batch_size) do |batch|
      model_log_ids = batch.map do |model_instance|
        { id: model_instance.auditable_id,
          user_id: model_instance.user_id }
      end
      UpdateUserIdsFromAuditLogsWorker.perform_async(model.constantize, model_log_ids)
    end
  end
end
