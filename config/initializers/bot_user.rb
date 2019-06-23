module BotUser
  def find_bot_user(id)
    User.where(id: id).first
  end

  def find_or_create_bot_user(id, name)
    bot_user = find_bot_user(id)
    return bot_user if bot_user.present?

    User
      .find_or_initialize_by(id: id, full_name: name)
      .save(validate: false)

    find_bot_user(id)
  end
end

ActiveSupport.on_load(:after_initialize, :yield => true) do
  include BotUser
  if !Rails.env.test? && !(defined?(is_running_migration?) && is_running_migration?)
    # SMS_REMINDER_BOT_USER = find_or_create_bot_user(ENV.fetch('APPOINTMENT_NOTIFICATION_BOT_USER_UUID'),
    #                                                 ENV.fetch('APPOINTMENT_NOTIFICATION_BOT_USER_NAME'))
  end
end
