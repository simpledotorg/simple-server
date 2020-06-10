require "flipper/adapters/active_record"
require "flipper/middleware/memoizer"

Flipper.configure do |config|
  config.default do
    adapter = Flipper::Adapters::ActiveRecord.new
    Flipper.new(adapter)
  end
end

Rails.configuration.middleware.use Flipper::Middleware::Memoizer, preload_all: true
