module Api::V3::LogApiUsageByUsers
  extend ActiveSupport::Concern
  included do
    before_action :log_api_usage

    def log_api_usage
      NewRelic::Agent.add_custom_attributes(user_id: current_user&.id || 'no-user-id')
      Loggers::ApiUsageLogger.tagged(params[:controller], params[:action], current_user&.id || "no-user-id") { Loggers::ApiUsageLogger.info(1) }
    end
  end
end
