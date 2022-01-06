# frozen_string_literal: true

require "rails_helper"

RSpec.describe OneOff::FixKokaHcBps do
  it "fixes BP dates in Koka Health Center" do
    allow(CountryConfig).to receive(:current).and_return(abbreviation: "ET")
    facility = create(:facility, name: "Koka Health Center")
    bp = create(:blood_pressure, :with_encounter, facility: facility, recorded_at: "2013-04-30")

    described_class.call

    expect(bp.reload.recorded_at.strftime("%Y-%m-%d")).to eq("2021-01-08")
  end

  it "updates the patient's registration date correctly" do
    allow(CountryConfig).to receive(:current).and_return(abbreviation: "ET")
    facility = create(:facility, name: "Koka Health Center")
    patient = create(:patient, recorded_at: "2013-04-30")

    _good_bp = create(:blood_pressure, :with_encounter, patient: patient, facility: facility, recorded_at: "2020-10-30")
    _bad_bp = create(:blood_pressure, :with_encounter, patient: patient, facility: facility, recorded_at: "2013-04-30")

    described_class.call

    expect(patient.reload.recorded_at.strftime("%Y-%m-%d")).to eq("2020-10-30")
  end

  it "doesn't touch BPs with correct dates" do
    allow(CountryConfig).to receive(:current).and_return(abbreviation: "ET")
    facility = create(:facility, name: "Koka Health Center")
    bp = create(:blood_pressure, :with_encounter, facility: facility, recorded_at: "2021-08-04")

    expect { described_class.call }.not_to change { bp.reload.recorded_at }
  end

  it "doesn't touch BPs at other facilities" do
    allow(CountryConfig).to receive(:current).and_return(abbreviation: "ET")
    facility = create(:facility, name: "Another Health Center")
    bp = create(:blood_pressure, :with_encounter, facility: facility, recorded_at: "2013-04-30")

    expect { described_class.call }.not_to change { bp.reload.recorded_at }
  end

  it "doesn't touch BPs in other countries" do
    allow(CountryConfig).to receive(:current).and_return(abbreviation: "IN")
    facility = create(:facility, name: "Koka Health Center")
    bp = create(:blood_pressure, :with_encounter, facility: facility, recorded_at: "2013-04-30")

    expect { described_class.call }.not_to change { bp.reload.recorded_at }
  end
end
