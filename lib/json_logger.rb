class JsonLogger < Ougai::Logger
  include ActiveSupport::LoggerThreadSafeLevel
  include ActiveSupport::LoggerSilence

  def initialize(*args)
    super
    @before_log = lambda do |data|
      if (user_hash = RequestStore.store[:current_user])
        data[:usr] = {
          id: user_hash["usr.id"],
          access_level: user_hash["usr.access_level"],
          sync_approval_status: user_hash["usr.sync_approval_status"]
        }
      end
    end

    after_initialize if respond_to? :after_initialize
  end

  def create_formatter
    LoggingExtensions.default_log_formatter
  end
end
