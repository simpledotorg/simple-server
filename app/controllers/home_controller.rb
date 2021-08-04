# frozen_string_literal: true

class HomeController < AdminController
  layout "application_v2"

  skip_after_action :verify_authorization_attempted, only: [:index]

  def index
    unless current_admin.feature_enabled?(:webpack)
      redirect_to my_facilities_overview_path(request.query_parameters)
    end
  end
end
