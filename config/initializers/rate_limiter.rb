module RateLimit
  DISABLED_ENVS = %w[sandbox qa android_review review].to_set
  RACK_ATTACK_OPTIONS = {
    dashboard_auth: {limit: 5, period: 1.minute},
    users_find: {limit: 5, period: 1.minute},
    users_activate_by_ip: {limit: 5, period: 1.minute},
    users_activate_by_user: {limit: 5, period: 30.minutes},
    patient_lookup: {limit: 5, period: 10.second}
  }

  def self.enabled?
    !SimpleServer.env.in?(DISABLED_ENVS)
  end

  def self.logger(extra_fields = {})
    fields = {module: :rate_limit}.merge(extra_fields)
    Rails.logger.child(fields)
  end

  Rack::Attack.throttled_responder = lambda do |_request|
    [429, {}, ["Too many requests. Please wait and try again later.\n"]]
  end

  Rack::Attack.throttle(:throttle_logins, RACK_ATTACK_OPTIONS[:dashboard_auth]) do |req|
    if enabled? && req.post? && req.path.start_with?("/email_authentications/sign_in")
      req.ip
    end
  end

  Rack::Attack.throttle(:throttle_password_edit, RACK_ATTACK_OPTIONS[:dashboard_auth]) do |req|
    if enabled? && req.get? && req.path.start_with?("/email_authentications/password/edit")
      req.ip
    end
  end

  Rack::Attack.throttle(:throttle_password_reset, RACK_ATTACK_OPTIONS[:dashboard_auth]) do |req|
    if (req.post? || req.put?) && req.path.start_with?("/email_authentications/password")
      req.ip
    end
  end

  Rack::Attack.throttle(:throttle_users_find, RACK_ATTACK_OPTIONS[:users_find]) do |req|
    if enabled? && req.post? && req.path.start_with?("/api/v4/users/find")
      req.ip
    end
  end

  Rack::Attack.throttle(:throttle_users_activate_by_ip, RACK_ATTACK_OPTIONS[:users_activate_by_ip]) do |req|
    if enabled? && req.post? && req.path.start_with?("/api/v4/users/activate")
      req.ip
    end
  end

  Rack::Attack.throttle(:throttle_users_activate_by_user, RACK_ATTACK_OPTIONS[:users_activate_by_user]) do |req|
    if enabled? && req.post? && req.path.start_with?("/api/v4/users/activate")
      request = ActionDispatch::Request.new(req.env)
      request.params.dig("user", "id")
    end
  end

  Rack::Attack.throttle(:throttle_patient_lookup, RACK_ATTACK_OPTIONS[:patient_lookup]) do |req|
    if enabled? && req.post? && req.path.start_with?("/api/v4/patients/lookup")
      req.ip
    end
  end

  ActiveSupport::Notifications.subscribe(/throttle.rack_attack/) do |name, start, finish, request_id, payload|
    request = ActionDispatch::Request.new(payload[:request].env)
    RateLimit.logger.info "Too many login attempts for user #{request.params.dig(:user, :id)}"
  end
end

