# frozen_string_literal: true

module LoggingExtensions
  # Create our default log formatter so that we can use it everywhere, and keep formats consistent.
  def self.default_log_formatter
    @default_log_formatter = if Rails.env.development? || Rails.env.profiling? || Rails.env.test?
      Ougai::Formatters::Readable.new
    else
      Ougai::Formatters::Bunyan.new
    end
  end
end

# Ensure Tagged Logging formatter plays nicely with Ougai.
# See also https://github.com/tilfin/ougai/wiki/Use-as-Rails-logger
module ActiveSupport::TaggedLogging::Formatter
  def call(severity, time, progname, data)
    data = {msg: data.to_s} unless data.is_a?(Hash)
    tags = current_tags
    data[:tags] = tags if tags.present?
    _call(severity, time, progname, data)
  end
end

# Monkeypatch in the Rails 6 ActiveSupport::TaggedLogging initializer.
# This ensures we always get a new logger that also has our default
# formatter from Ougai. Taken from https://github.com/rails/webpacker/issues/1155#issuecomment-442208940
# and tweaked a bit for our particular logging setup.
# This particular patch can be removed when we get to Rails 6.
if ActiveSupport::VERSION::MAJOR < 6
  module ActiveSupport
    module TaggedLogging
      def self.new(logger)
        logger = logger.dup
        logger.formatter = LoggingExtensions.default_log_formatter
        logger.formatter.extend Formatter
        logger.extend(self)
      end
    end
  end
else
  ActiveSupport::Deprecation.warn("No longer need to monkeypatch ActiveSupport::TaggedLogging")
end
