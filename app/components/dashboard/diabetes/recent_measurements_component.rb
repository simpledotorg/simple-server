class Dashboard::Diabetes::RecentMeasurementsComponent < ApplicationComponent
  include Reports::RegionsUrlHelper

  attr_reader :region, :user, :recent_blood_sugars, :display_model, :page

  def initialize(region: nil, user: nil, recent_blood_sugars:, display_model:, page:)
    @region = region
    @user = user
    @recent_blood_sugars = recent_blood_sugars
    @display_model = display_model
    @page = page
    @recent_blood_sugars.first.risk_state
  end

  private

  def risk_state_color_class(blood_sugar)
    case blood_sugar.risk_state
    when :bs_over_300 then "c-red"
    when :bs_200_to_300 then "c-amber"
    else "text-muted"
    end
  end
end
