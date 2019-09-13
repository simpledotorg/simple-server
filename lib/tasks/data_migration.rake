namespace :data_migration do
  desc "Create master users for users"
  task create_master_users_for_users: :environment do
    OldUser.where.not(sync_approval_status: nil).all.each do |user|
      next if User.find_by(id: user.id).present?
      user.transaction do
        user_attributes = user.attributes.with_indifferent_access
        master_user = User.create(user_attributes.slice(
          :id,
          :full_name,
          :sync_approval_status,
          :sync_approval_status_reason,
          :device_created_at,
          :device_updated_at,
          :created_at,
          :updated_at,
          :deleted_at
        ))

        phone_number_authentication = PhoneNumberAuthentication.create(user_attributes.slice(
          :phone_number,
          :password_digest,
          :otp,
          :otp_valid_until,
          :registration_facility_id,
          :logged_in_at,
          :access_token,
          :created_at,
          :updated_at,
          :deleted_at
        ))

        master_user.user_authentications.create(
          authenticatable: phone_number_authentication
        )
      end
    end
  end

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
end
