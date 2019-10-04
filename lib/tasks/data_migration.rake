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
