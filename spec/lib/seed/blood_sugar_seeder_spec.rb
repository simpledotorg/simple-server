require "rails_helper"

RSpec.describe Seed::BloodSugarSeeder do
  let(:config) { Seed::Config.new }

  it "does nothing if the facility does not have DM enabled" do
    facility = create(:facility, enable_diabetes_management: false)
    _user = create(:user, registration_facility: facility)
    patients = create_list(:patient, 2, assigned_facility: facility)

    expect {
      result = described_class.call(facility: facility, user_ids: facility.user_ids, config: config)
      expect(result).to eq({})
    }.to change { BloodSugar.count }.by(0)
      .and change { Encounter.count }.by(0)
      .and change { Observation.count }.by(0)
  end

  it "creates blood sugars and related objects" do
    facility = create(:facility, enable_diabetes_management: true)
    _user = create(:user, registration_facility: facility)
    patients = create_list(:patient, 2, assigned_facility: facility)
    expected_count = config.max_blood_sugars_to_create * 2

    expect {
      described_class.call(facility: facility, user_ids: facility.user_ids, config: config)
    }.to change { BloodSugar.count }.by(expected_count)
      .and change { Encounter.count }.by(expected_count)
      .and change { Observation.count }.by(expected_count)
    patients.each do |patient|
      patient.blood_sugars.each do |blood_sugar|
        expect(blood_sugar).to be_valid
        expect(blood_sugar.observation).to be_valid
        expect(blood_sugar.encounter).to be_valid
        expect(blood_sugar.user).to eq(blood_sugar.observation.user)
      end
    end
  end
end
