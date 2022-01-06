# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seed::BloodPressureSeeder do
  let(:config) { Seed::Config.new }

  it "creates BPs and related objects" do
    facility = create(:facility)
    _user = create(:user, registration_facility: facility)
    patients = create_list(:patient, 2, assigned_facility: facility)
    expected_count = config.max_bps_to_create * 2

    expect {
      Seed::BloodPressureSeeder.call(facility: facility, user_ids: facility.user_ids, config: config)
    }.to change { BloodPressure.count }.by(expected_count)
      .and change { Encounter.count }.by(expected_count)
      .and change { Observation.count }.by(expected_count)
    patients.each do |patient|
      patient.blood_pressures.each do |bp|
        expect(bp).to be_valid
        expect(bp.observation).to be_valid
        expect(bp.encounter).to be_valid
        expect(bp.user).to eq(bp.observation.user)
      end
    end
  end
end
