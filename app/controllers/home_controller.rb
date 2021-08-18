# frozen_string_literal: true

class HomeController < AdminController
  layout "application_v2"

  before_action :set_organization, only: [:edit, :update, :destroy]
  skip_after_action :verify_authorization_attempted, only: [:index]

  def index
    authorize { current_admin.accessible_organizations(:manage).any? }
    @organization = current_admin.accessible_organizations(:manage).first
    
    unless current_admin.feature_enabled?(:dashboard_ui_refresh)
      redirect_to my_facilities_overview_path(request.query_parameters)
    end
  end
end
