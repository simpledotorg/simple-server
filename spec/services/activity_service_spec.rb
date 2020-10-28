require "rails_helper"

RSpec.describe ActivityService do
  let(:facility_group) { create(:facility_group) }
  let(:facility_1) { create(:facility, facility_group: facility_group, district: "District 1") }
  let(:facility_2) { create(:facility, facility_group: facility_group, district: "District 2") }

  let(:june_1) { Date.new(2020, 6, 1) }
  let(:june_2) { Date.new(2020, 6, 2) }
  let(:june_3) { Date.new(2020, 6, 3) }
  let(:july_1) { Date.new(2020, 7, 1) }
  let(:july_2) { Date.new(2020, 7, 2) }
  let(:july_3) { Date.new(2020, 7, 3) }
  let(:aug_1) { Date.new(2020, 8, 1) }
  let(:aug_2) { Date.new(2020, 8, 2) }
  let(:aug_3) { Date.new(2020, 8, 3) }

  describe "registrations" do
    it "returns registrations for a facility" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_1)
      end

      activity_service = ActivityService.new(facility_1)

      Timecop.freeze(aug_3) do
        expect(activity_service.registrations).to eq(june_1 => 3, july_1 => 1, aug_1 => 2)
      end
    end

    it "returns registrations for a facility group" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_1)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_2)
      end

      activity_service = ActivityService.new(facility_group)

      Timecop.freeze(aug_3) do
        expect(activity_service.registrations).to eq(june_1 => 4, july_1 => 3, aug_1 => 4)
      end
    end

    it "returns registrations for a facility district" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_1)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_2)
      end

      activity_service = ActivityService.new(FacilityDistrict.new(name: "District 1"))

      Timecop.freeze(aug_3) do
        expect(activity_service.registrations).to eq(june_1 => 3, july_1 => 1, aug_1 => 2)
      end
    end

    it "can be grouped further" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_1)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_2)
      end

      activity_service = ActivityService.new(facility_group, group: :registration_facility_id)

      Timecop.freeze(aug_3) do
        expect(activity_service.registrations).to eq(
          [june_1, facility_1.id] => 3,
          [july_1, facility_1.id] => 1,
          [aug_1, facility_1.id] => 2,
          [june_1, facility_2.id] => 1,
          [july_1, facility_2.id] => 2,
          [aug_1, facility_2.id] => 2
        )
      end
    end

    it "can be grouped by day" do
      [
        june_1, june_1,
        june_2,
        july_1, july_1, july_1,
        aug_1,
        aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_1)
      end

      activity_service = ActivityService.new(facility_1, period: :day)

      Timecop.freeze(aug_3) do
        expect(activity_service.registrations).to include(
          june_1 => 2,
          june_2 => 1,
          july_1 => 3,
          aug_1 => 1,
          aug_2 => 1
        )

        # All other days are zeros
        other_days = activity_service.registrations.except(june_1, june_2, july_1, aug_1, aug_2)
        expect(other_days.values.uniq).to contain_exactly(0)
      end
    end

    it "can exclude the current period" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_1)
      end

      activity_service = ActivityService.new(facility_1, include_current_period: false)

      Timecop.freeze(aug_3) do
        expect(activity_service.registrations).to eq(june_1 => 3, july_1 => 1)
      end
    end

    it "can return only the last N periods" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_1)
      end

      activity_service = ActivityService.new(facility_1, last: 2)

      Timecop.freeze(aug_3) do
        expect(activity_service.registrations).to eq(july_1 => 1, aug_1 => 2)
      end
    end

    it "can return diabetes patients only" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_1)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :diabetes, recorded_at: date, registration_facility: facility_1)
      end

      activity_service = ActivityService.new(facility_1, diagnosis: :diabetes)

      Timecop.freeze(aug_3) do
        expect(activity_service.registrations).to eq(june_1 => 1, july_1 => 2, aug_1 => 2)
      end
    end

    it "can return all patients" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_1)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :diabetes, recorded_at: date, registration_facility: facility_1)
      end

      activity_service = ActivityService.new(facility_1, diagnosis: :all)

      Timecop.freeze(aug_3) do
        expect(activity_service.registrations).to eq(june_1 => 4, july_1 => 3, aug_1 => 4)
      end
    end
  end
end
