Raven.configure do |config|
  config.environments = %w(staging production)
  config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
end
