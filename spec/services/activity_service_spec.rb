require "rails_helper"

RSpec.describe ActivityService do

  it "something" do
    region = create(:facility)
    result = ActivityService.new(region).call
    pp result
  end
end