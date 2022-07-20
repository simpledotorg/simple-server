class Dashboard::Diabetes::RegistrationsAndFollowUpsByUserComponent < ApplicationComponent
  include Reports::RegionsHelper
  include DashboardHelper

  attr_reader :region, :repository, :period_range, :current_admin

  def initialize(region:, repository:, period_range:, current_admin:)
    @region = region
    @repository = repository
    @period_range = period_range
    @current_admin = current_admin
  end
end
