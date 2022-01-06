# frozen_string_literal: true

module SidekiqMiddleware
  class SetLocalTimeZone
    def call(_worker, _job, _queue)
      Time.use_zone(Rails.application.config.country[:time_zone] || "UTC") { yield }
    end
  end
end
