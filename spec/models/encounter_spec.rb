# frozen_string_literal: true

require "rails_helper"

describe Encounter, type: :model do
  describe "Associations" do
    it { should belong_to(:patient).optional }
    it { should belong_to(:facility) }
    it { should have_many(:observations) }
    it { should have_many(:blood_pressures) }
  end

  let!(:user) { create(:user) }
  let!(:facility) { create(:facility) }
  let!(:patient) { create(:patient, registration_facility: facility) }
  let!(:blood_pressure) { create(:blood_pressure, patient: patient) }
  let!(:timezone_offset) { 3600 }

  context "#encountered_on" do
    it "returns the encountered_on in the correct timezone" do
      Timecop.travel(DateTime.new(2019, 1, 1)) do
        expect(Encounter.generate_encountered_on(Time.now, 24 * 60 * 60)).to eq(Date.new(2019, 1, 2))
      end
    end
  end

  context "#generate_id" do
    it "generates the same encounter id consistently" do
      encountered_on = Encounter.generate_encountered_on(blood_pressure.recorded_at, timezone_offset)

      id_1 = Encounter.generate_id(facility.id, patient.id, encountered_on)
      id_2 = Encounter.generate_id(facility.id, patient.id, encountered_on)

      expect(id_1).to eq(id_2)
    end
  end

  describe "Scopes" do
    describe ".for_sync" do
      it "includes discarded encounters" do
        discarded_encounter = create(:encounter, deleted_at: Time.now)

        expect(described_class.for_sync).to include(discarded_encounter)
      end
    end
  end
end
