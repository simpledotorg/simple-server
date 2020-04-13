module Api::V2::LogApiUsageByUsers
  extend ActiveSupport::Concern
  included do
    before_action :log_api_usage

    def log_api_usage
      Loggers::ApiUsageLogger.logger.tagged(params[:controller], params[:action], current_user&.id || "no-user-id") { Loggers::ApiUsageLogger.logger.info(1) }
    end
  end
end
