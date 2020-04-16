require 'active_support/tagged_logging'
require 'logger'

class Loggers::ApiUsageLogger < ::Logger
  include ActiveSupport::TaggedLogging

  class << self
    attr_accessor :logger
    delegate :tagged, :info, :warn, :debug, :error, to: :logger
  end

  class Formatter < ActiveSupport::Logger::Formatter
    include ActiveSupport::TaggedLogging::Formatter
  end

  def initialize(target = STDOUT)
    super(target)
    self.formatter = Formatter.new
  end
end

