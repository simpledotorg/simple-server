# Patch TaggedLogging for compatibility with JSON logging
# See https://github.com/tilfin/ougai/wiki/Use-as-Rails-logger for details

unless SIMPLE_SERVER_ENV == "review"
  module ActiveSupport::TaggedLogging::Formatter
    def call(severity, time, progname, data)
      data = {msg: data.to_s} unless data.is_a?(Hash)
      tags = current_tags
      data[:tags] = tags if tags.present?
      _call(severity, time, progname, data)
    end
  end
end
