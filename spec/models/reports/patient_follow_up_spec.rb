require "rails_helper"

RSpec.describe Reports::PatientFollowUp, {type: :model, reporting_spec: true} do
  describe "Associations" do
    it { should belong_to(:patient) }
    it { should belong_to(:facility) }
    it { should belong_to(:user) }
  end

  around do |example|
    freeze_time_for_reporting_specs(example)
  end

  it "contains records for patient BPs" do
    patient = create(:patient, recorded_at: june_2021[:long_ago])
    user = create(:user)
    facility = create(:facility)

    create(
      :blood_pressure,
      patient: patient,
      user: user,
      facility: facility,
      recorded_at: june_2021[:now]
    )

    RefreshReportingViews.call

    expect(described_class.count).to eq(1)
    follow_up = described_class.find_by(patient: patient, user: user, facility: facility)
    expect(follow_up.month_string).to eq(june_2021[:month_string])
  end
end
