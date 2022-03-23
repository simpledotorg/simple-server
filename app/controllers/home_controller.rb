# frozen_string_literal: true

class HomeController < AdminController
  layout "application_v2"

  skip_after_action :verify_authorization_attempted, only: [:index]

  def index
    unless current_admin.feature_enabled?(:dashboard_ui_refresh)
      redirect_to root_path(request.query_parameters)
    end
  end
end
