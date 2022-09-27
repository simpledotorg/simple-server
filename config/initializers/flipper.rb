require "flipper/adapters/active_record"
require "flipper/middleware/memoizer"

Flipper.register(:power_users) do |actor|
  actor.respond_to?(:power_user?) && actor.power_user?
end

Flipper.configure do |config|
  config.default do
    adapter = Flipper::Adapters::ActiveRecord.new
    Flipper.new(adapter)
  end
end
