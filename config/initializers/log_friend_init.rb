if Rails.env.development? || Rails.env.test?
  require "log_friend"
  Object.include(LogFriend::Extensions)
end
