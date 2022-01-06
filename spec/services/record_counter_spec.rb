# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecordCounter do
  let(:user) { create(:user) }
  let(:facility) { create(:facility) }

  it "sends total counts as gauges to Statsd" do
    patients = create_list(:patient, 3, registration_facility: facility, registration_user: user)
    create(:appointment, patient: patients.first, facility: facility, user: user)
    create(:blood_pressure, patient: patients.first, facility: facility, user: user)

    expect(Statsd.instance).to receive(:gauge).with(anything, 0).at_least(1).times
    expect(Statsd.instance).to receive(:gauge).with("counts.Appointment", 1)
    expect(Statsd.instance).to receive(:gauge).with("counts.BloodPressure", 1)
    expect(Statsd.instance).to receive(:gauge).with("counts.Facility", 2)
    expect(Statsd.instance).to receive(:gauge).with("counts.FacilityGroup", 2)
    expect(Statsd.instance).to receive(:gauge).with("counts.MedicalHistory", 3)
    expect(Statsd.instance).to receive(:gauge).with("counts.Patient", 3)
    expect(Statsd.instance).to receive(:gauge).with("counts.Region", Region.count)
    expect(Statsd.instance).to receive(:gauge).with("counts.User", 1)

    expect(Statsd.instance).to receive(:histogram)
      .with("counts.facilities_per_district", kind_of(Numeric)).at_least(1).times
    expect(Statsd.instance).to receive(:histogram)
      .with("counts.assigned_patients_per_facility", kind_of(Numeric)).at_least(1).times
    expect(Statsd.instance).to receive(:histogram)
      .with("counts.assigned_patients_per_block", kind_of(Numeric)).at_least(1).times
    RecordCounter.new.call
  end
end
