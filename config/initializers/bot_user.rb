module BotUser
end

ActiveSupport.on_load(:after_initialize, :yield => true) { SMS_REMINDER_BOT_USER = nil }
