require "rails_helper"

RSpec.describe AssignedPatientsQuery do
  let(:user) { create(:user) }

  it "should include only assigned hypertension patients" do
    facility = create(:facility)
    other_facility = create(:facility)
    create(:patient, registration_facility: facility, registration_user: user)
    create(:patient, registration_facility: other_facility, registration_user: user)
    create(:patient, :without_hypertension, registration_facility: facility, registration_user: user)
    expect(described_class.new.count(facility, :month).values.first).to eq 1
  end

  it "excludes dead patients" do
    facility = create(:facility)
    create(:patient, registration_facility: facility, status: :dead, registration_user: user)
    create(:patient, registration_facility: facility, recorded_at: 2.months.ago, registration_user: user)
    create(:patient, registration_facility: facility, recorded_at: 1.months.ago, registration_user: user)
    result = described_class.new.count(facility, :month)
    expect(result.size).to eq(2)
    expect(result).to eq({
      1.month.ago.to_period => 1,
      2.month.ago.to_period => 1,
    })
  end
end
