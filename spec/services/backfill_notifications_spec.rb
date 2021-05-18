require "rails_helper"

RSpec.describe BackfillNotifications do
  it "works" do
    Timecop.freeze(5.weeks.ago) do
      create_list(:communication, 2, :with_appointment)
    end
    Timecop.freeze(3.weeks.ago) do
      create_list(:communication, 2, :with_appointment)
    end
    expect {
      BackfillNotifications.call
    }.to change { Notification.count }.by(4)
  end
end