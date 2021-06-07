require "rails_helper"

RSpec.describe Reports::RepositoryCacheWarmer, type: :model do
  let(:user) { create(:user) }

  it "successfully completes" do
    facility = create(:facility)
    patients = create_list(:patient, 2, registration_user: user)
    patients.each do |patient|
      create(:blood_pressure, patient: patient, facility: facility,
                              recorded_at: 3.months.ago, user: user)
    end
    range = (3.months.ago.to_period..Period.current)

    described_class.call(region: facility, period: Period.current)

    expect_any_instance_of(BPMeasuresQuery).to receive(:count).never
    expect_any_instance_of(FollowUpsQuery).to receive(:hypertension).never

    repo = Reports::Repository.new(facility, periods: range)
    repo.bp_measures_by_user
    repo.hypertension_follow_ups
  end
end
