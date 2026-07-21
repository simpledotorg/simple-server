module Traceability
  module LogSubscriber
    module_function

    def call(payload)
      marker = payload[:boundary] == "request" ? "SIMPLE-REQUEST-LINE" : "SIMPLE-DATA-LINE"

      Rails.logger.info(payload.merge(msg: marker))
    end
  end
end
