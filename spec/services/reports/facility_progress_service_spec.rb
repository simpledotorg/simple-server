require "rails_helper"

RSpec.describe Reports::FacilityProgressService, type: :model do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }

  it "returns all dimension combinations" do
    service = described_class.new(facility, Period.current)
    dimensions = service.dimension_combinations_for(:registrations)
    # (2 diagnosis options) * (4 gender options) + 1 special case of all / all
    expect(dimensions.size).to eq(9)
    expect(dimensions.all? { |d| d.indicator == :registrations }).to be true
    expect(dimensions.count { |d| d.diagnosis == :diabetes }).to eq(4)
    expect(dimensions.count { |d| d.diagnosis == :hypertension }).to eq(4)
    expect(dimensions.count { |d| d.diagnosis == :all }).to eq(1)
  end

  it "returns daily follow up counts for HTN / DM patients" do
    Timecop.freeze do
      facility = create(:facility)
      patient1 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
      patient2 = create(:patient, :hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
      patient3 = create(:patient, :without_hypertension, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
      patient4 = create(:patient, :diabetes, registration_facility: facility, registration_user: user, recorded_at: 2.months.ago)
      create(:appointment, recorded_at: 2.days.ago, patient: patient1, facility: facility, user: user)
      create(:blood_pressure, recorded_at: 2.days.ago, patient: patient2, facility: facility, user: user)
      create(:blood_pressure, recorded_at: 2.days.ago, patient: patient3, facility: facility, user: user)
      create(:blood_sugar, recorded_at: 2.days.ago, patient: patient4, facility: facility, user: user)
      create(:blood_pressure, recorded_at: 2.minutes.ago, patient: patient2, facility: facility, user: user)
      service = described_class.new(facility, Period.current)

      refresh_views
      service = described_class.new(facility, Period.current)
      expect(service.daily_follow_ups(2.days.ago)).to eq(3)
      expect(service.daily_follow_ups(1.days.ago)).to eq(0)
      expect(service.daily_follow_ups(Date.current)).to eq(1)
    end
  end
end
