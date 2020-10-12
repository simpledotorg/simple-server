module RateLimit
  def self.auth_api_options
    # 5 requests / minute
    limit_proc = proc { |_req| 5 }
    period_proc = proc { |_req| 1.minute }

    {limit: limit_proc, period: period_proc}
  end
end

class Rack::Attack
  throttle("throttle_logins", RateLimit.auth_api_options) do |req|
    if req.post? && req.path.start_with?("/email_authentications/sign_in")
      req.ip
    end
  end

  throttle("throttle_password_modifications", RateLimit.auth_api_options) do |req|
    if req.path.start_with?("/email_authentications/password")
      req.ip
    end
  end
end if Rails.env.production?
