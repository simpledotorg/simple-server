require "rails_helper"

RSpec.describe RecordCounter do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }

  it "sends total counts as gauges to Metrics" do
    patients = create_list(:patient, 3, registration_facility: facility, registration_user: user)
    create(:appointment, patient: patients.first, facility: facility, user: user)
    create(:blood_pressure, patient: patients.first, facility: facility, user: user)

    expect(Metrics.instance).to receive(:gauge).with(anything, 0).at_least(1).times
    expect(Metrics.instance).to receive(:gauge).with("appointments", 1)
    expect(Metrics.instance).to receive(:gauge).with("blood_pressures", 1)
    expect(Metrics.instance).to receive(:gauge).with("facilities", 2)
    expect(Metrics.instance).to receive(:gauge).with("facility_groups", 2)
    expect(Metrics.instance).to receive(:gauge).with("medical_histories", 3)
    expect(Metrics.instance).to receive(:gauge).with("patients", 3)
    expect(Metrics.instance).to receive(:gauge).with("regions", Region.count)
    expect(Metrics.instance).to receive(:gauge).with("users", 1)

    expect(Metrics.instance).to receive(:histogram)
      .with("facilities_per_district", kind_of(Numeric)).at_least(1).times
    expect(Metrics.instance).to receive(:histogram)
      .with("assigned_patients_per_facility", kind_of(Numeric)).at_least(1).times
    expect(Metrics.instance).to receive(:histogram)
      .with("assigned_patients_per_block", kind_of(Numeric)).at_least(1).times
    RecordCounter.new.call
  end
end
