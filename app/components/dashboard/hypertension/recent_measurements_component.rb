class Dashboard::Hypertension::RecentMeasurementsComponent < ApplicationComponent
  include Reports::RegionsUrlHelper

  attr_reader :region, :user, :recent_blood_pressures, :display_model, :page

  def initialize(recent_blood_pressures:, display_model:, page:, region: nil, user: nil)
    @region = region
    @user = user
    @recent_blood_pressures = recent_blood_pressures
    @display_model = display_model
    @page = page
  end

  def subtitle
    subtitle = "A log of BP measures taken"
    subtitle = " by healthcare workers at #{region.name}" if display_model == :facility
    subtitle = " by this healthcare worker" if display_model == :user
    subtitle
  end
end
