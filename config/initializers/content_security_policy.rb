# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy
if Rails.env.production?
  Rails.application.config.content_security_policy do |policy|
    policy.default_src(:self, :https)
    policy.font_src(:self, :https, :data)
    policy.img_src(:self, :https, :data)
    policy.object_src(:none)
    policy.script_src(:self, :https, :unsafe_inline)
    policy.style_src(:self, :https, :unsafe_inline)

    report_uri = Addressable::URI.parse(ENV["SENTRY_SECURITY_HEADER_ENDPOINT"])
    report_uri.query_values = report_uri.query_values&.merge(sentry_environment: ENV["SENTRY_CURRENT_ENV"])
    policy.report_uri(report_uri.to_s)
  end

  # If you are using UJS then enable automatic nonce generation
  # Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

  Rails.application.config.content_security_policy_report_only = true
end

