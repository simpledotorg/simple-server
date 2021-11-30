unless SimpleServer.env.sandbox? || SimpleServer.env.qa? || SimpleServer.env.android_review? || SimpleServer.env.review?
  module RateLimit
    def self.auth_api_options
      limit_proc = proc { |_req| 5 }
      period_proc = proc { |_req| 1.minute }

      {limit: limit_proc, period: period_proc}
    end

    def self.user_api_options
      limit_proc = proc { |_req| 5 }
      period_proc = proc { |_req| 30.minutes }

      {limit: limit_proc, period: period_proc}
    end

    def self.patient_lookup_api_options
      limit_proc = proc { |_req| 5 }
      period_proc = proc { |_req| 5.second }

      {limit: limit_proc, period: period_proc}
    end
  end

  class Rack::Attack
    self.throttled_response = lambda do |_request|
      [429, {}, ["Too many requests. Please wait and try again later.\n"]]
    end

    throttle("throttle_logins", RateLimit.auth_api_options) do |req|
      if req.post? && req.path.start_with?("/email_authentications/sign_in")
        req.ip
      end
    end

    throttle("throttle_password_edit", RateLimit.auth_api_options) do |req|
      if req.get? && req.path.start_with?("/email_authentications/password/edit")
        req.ip
      end
    end

    throttle("throttle_password_reset", RateLimit.auth_api_options) do |req|
      if (req.post? || req.put?) && req.path.start_with?("/email_authentications/password")
        req.ip
      end
    end

    throttle("throttle_user_find", RateLimit.auth_api_options) do |req|
      if req.post? && req.path.start_with?("/api/v4/users/find")
        req.ip
      end
    end

    throttle("throttle_user_activate", RateLimit.user_api_options) do |req|
      if req.post? && req.path.start_with?("/api/v4/users/activate") && SimpleServer.env.production?
        req.ip
      end
    end

    throttle("throttle_patient_lookup", RateLimit.patient_lookup_api_options) do |req|
      if req.get? && req.path.match?(/\/api\/v4\/patients\/.+/)
        req.ip
      end
    end
  end

end
