require "rails_helper"

RSpec.describe ActivityService do

  it "something" do
    region = create(:facility)
    activity_service = ActivityService.new(region)
    pp activity_service.registrations
    pp activity_service.follow_ups
    pp activity_service.controlled_visits
  end
end
