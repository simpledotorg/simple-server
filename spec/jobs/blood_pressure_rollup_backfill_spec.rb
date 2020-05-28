require 'rails_helper'

RSpec.describe BloodPressureRollupBackfill, type: :job do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:facility) { create(:facility) }

  it "works" do
    bp1 = create(:blood_pressure, :under_control, recorded_at: Time.parse("January 1 2020"), facility: facility, user: user)
    bp2 = create(:blood_pressure, :hypertensive, recorded_at: Time.parse("January 5 2020"), facility: facility, user: user)
    LatestBloodPressuresPerPatientPerMonth.refresh

    perform_enqueued_jobs do
      expect {
        BloodPressureRollupBackfill.perform_later([bp1.patient, bp2.patient])
      }.to change { BloodPressureRollup.count }.by(1)
    end
  end
end
