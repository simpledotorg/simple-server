module BotUser
  def find_bot_user
    User.where(id: ENV.fetch('SMS_REMINDER_BOT_USER_UUID'))
  end

  def find_or_create_bot_user
    bot_user = find_bot_user
    return bot_user if bot_user.present?

    User
      .find_or_initialize_by(id: ENV.fetch('SMS_REMINDER_BOT_USER_UUID'),
                             full_name: ENV.fetch('SMS_REMINDER_BOT_USER_NAME'))
      .save(validate: false)

    find_bot_user
  end
end

ActiveSupport.on_load(:after_initialize, :yield => true) do
  include BotUser

  unless Rails.env.test?
    SMS_REMINDER_BOT_USER = find_or_create_bot_user
  end
end
