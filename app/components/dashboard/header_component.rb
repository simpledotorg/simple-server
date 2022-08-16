class Dashboard::HeaderComponent < ApplicationComponent
  include NavHelper

  attr_reader :region, :period, :current_admin, :with_ltfu

  def initialize(region:, period:, current_admin:, with_ltfu:)
    @region = region
    @period = period
    @current_admin = current_admin
    @with_ltfu = with_ltfu
  end

  def url_params
    request.params
  end

  def show_diabetes_link?
    region.diabetes_management_enabled?
  end

  def show_progress_tab_link?
    @region.facility_region? && current_admin.feature_enabled?(:dashboard_progress_reports)
  end

  def show_period_selector?
    true
  end
end
