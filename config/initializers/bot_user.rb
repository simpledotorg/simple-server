ActiveSupport.on_load(:after_initialize, :yield => true) do
  unless Rails.env.test?
    BOT_USER = User
                 .find_or_initialize_by(id: ENV.fetch('BOT_USER_UUID'),
                                        full_name: ENV.fetch('BOT_USER_NAME'))
                 .save(validate: false) && \
             User.find(ENV.fetch('BOT_USER_UUID'))
  end
end
