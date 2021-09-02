require "rails_helper"

RSpec.describe RecordCounter do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }

  it "sends total counts as gauges to Statsd" do
    patients = create_list(:patient, 3, registration_facility: facility, registration_user: user)
    create(:appointment, patient: patients.first, facility: facility, user: user)
    create(:blood_pressure, patient: patients.first, facility: facility, user: user)

    expect(Statsd.instance).to receive(:gauge).with(anything, 0)
    expect(Statsd.instance).to receive(:gauge).with("total_counts.Appointment", 1)
    expect(Statsd.instance).to receive(:gauge).with("total_counts.BloodPressure", 1)
    expect(Statsd.instance).to receive(:gauge).with("total_counts.Facility", 2)
    expect(Statsd.instance).to receive(:gauge).with("total_counts.FacilityGroup", 2)
    expect(Statsd.instance).to receive(:gauge).with("total_counts.Patient", 3)
    expect(Statsd.instance).to receive(:gauge).with("total_counts.Region", Region.count)
    expect(Statsd.instance).to receive(:gauge).with("total_counts.User", 1)

    RecordCounter.new.call
  end
end