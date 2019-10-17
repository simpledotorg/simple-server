module BotUser
  def find_bot_user(id)
    User.where(id: id).first
  end

  def find_or_create_bot_user(id, name)
    bot_user = find_bot_user(id)
    return bot_user if bot_user.present?
    current_time = Time.current
    User.find_or_initialize_by(
        id: id,
        full_name: name,
        sync_approval_status: User.sync_approval_statuses[:denied],
        sync_approval_status_reason: "Bot user doesn't require sync",
        device_created_at: current_time,
        device_updated_at: current_time).save(validate: false)

    find_bot_user(id)
  end
end

ActiveSupport.on_load(:after_initialize, :yield => true) do
  include BotUser
  if !Rails.env.test? && !(defined?(is_running_migration?) && is_running_migration?)
    SMS_REMINDER_BOT_USER = find_or_create_bot_user(ENV.fetch('APPOINTMENT_NOTIFICATION_BOT_USER_UUID'),
                                                    ENV.fetch('APPOINTMENT_NOTIFICATION_BOT_USER_NAME'))
  end
end
