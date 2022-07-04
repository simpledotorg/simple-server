class Dashboard::Diabetes::RecentMeasurementsComponent < ApplicationComponent
  include Reports::RegionsUrlHelper

  attr_reader :region, :user, :recent_blood_sugars, :display_model, :page

  def initialize(recent_blood_sugars:, display_model:, page:, region: nil, user: nil)
    @region = region
    @user = user
    @recent_blood_sugars = recent_blood_sugars
    @display_model = display_model
    @page = page
  end

  private

  def risk_state_color_class(blood_sugar)
    case blood_sugar.risk_state
    when :bs_over_300 then "c-red"
    when :bs_200_to_300 then "c-amber"
    else "text-muted"
    end
  end

  def subtitle
    subtitle = "A log of blood sugar measures taken"
    subtitle += " by healthcare workers at #{region.name}" if display_model == :facility
    subtitle += " by this healthcare worker" if display_model == :user
    subtitle
  end
end
