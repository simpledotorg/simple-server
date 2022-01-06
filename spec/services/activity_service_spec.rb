# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActivityService do
  let(:facility_group) { create(:facility_group) }
  let(:facility_1) { create(:facility, facility_group: facility_group, district: "District 1") }
  let(:facility_2) { create(:facility, facility_group: facility_group, district: "District 2") }

  let(:long_ago) { Date.new(2020, 1, 1) }
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
      # Excluded patients
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        create(:patient, :hypertension, recorded_at: date, registration_facility: facility_1)
      end

      # Included patients
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

  describe "follow ups" do
    it "returns follow ups for a facility" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1)

      Timecop.freeze(aug_3) do
        expect(activity_service.follow_ups).to eq(june_1 => 3, july_1 => 1, aug_1 => 2)
      end
    end

    it "returns follow ups for a facility group" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_2, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_group)

      Timecop.freeze(aug_3) do
        expect(activity_service.follow_ups).to eq(june_1 => 4, july_1 => 3, aug_1 => 4)
      end
    end

    it "can be grouped further" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_2, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_group, group: BloodPressure.arel_table[:facility_id])

      Timecop.freeze(aug_3) do
        expect(activity_service.follow_ups).to eq(
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
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, period: :day)

      Timecop.freeze(aug_3) do
        expect(activity_service.follow_ups).to include(
          june_1 => 2,
          june_2 => 1,
          july_1 => 3,
          aug_1 => 1,
          aug_2 => 1
        )

        # All other days are zeros
        other_days = activity_service.follow_ups.except(june_1, june_2, july_1, aug_1, aug_2)
        expect(other_days.values.uniq).to contain_exactly(0)
      end
    end

    it "can exclude the current period" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, include_current_period: false)

      Timecop.freeze(aug_3) do
        expect(activity_service.follow_ups).to eq(june_1 => 3, july_1 => 1)
      end
    end

    it "can return only the last N periods" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, last: 2)

      Timecop.freeze(aug_3) do
        expect(activity_service.follow_ups).to eq(july_1 => 1, aug_1 => 2)
      end
    end

    it "can return diabetes patients only" do
      # Excluded patients
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        htn_patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: htn_patient, facility: facility_1, recorded_at: date)
        create(:blood_sugar, patient: htn_patient, facility: facility_1, recorded_at: date)

        dm_patient_with_bp = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: dm_patient_with_bp, facility: facility_1, recorded_at: date)
      end

      # Included patients
      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :diabetes, recorded_at: long_ago)
        create(:blood_sugar, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, diagnosis: :diabetes)

      Timecop.freeze(aug_3) do
        expect(activity_service.follow_ups).to eq(june_1 => 1, july_1 => 2, aug_1 => 2)
      end
    end

    it "can return all patients" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        # We need encounters for these BPs since the generic follow up scope traverses Encounter records
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :diabetes, recorded_at: long_ago)
        # We need encounters for these blood sugars since the generic follow up scope traverses Encounter records
        create(:blood_sugar, :with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, diagnosis: :all)

      Timecop.freeze(aug_3) do
        expect(activity_service.follow_ups).to eq(june_1 => 4, july_1 => 3, aug_1 => 4)
      end
    end

    it "counts multiple visits in a month as one monthly followup" do
      multi_visit_patient = create(:patient, :hypertension, recorded_at: long_ago)

      [
        june_1, june_2, june_3,
        july_1
      ].each do |date|
        create(:bp_with_encounter, patient: multi_visit_patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1)

      Timecop.freeze(july_3) do
        expect(activity_service.follow_ups).to eq(june_1 => 1, july_1 => 1)
      end
    end

    it "counts multiple visits in a month as multiple daily followups" do
      multi_visit_patient = create(:patient, :hypertension, recorded_at: long_ago)

      [
        june_1, june_2, june_3
      ].each do |date|
        create(:bp_with_encounter, patient: multi_visit_patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, period: :day)

      Timecop.freeze(june_3) do
        expect(activity_service.follow_ups).to eq(june_1 => 1, june_2 => 1, june_3 => 1)
      end
    end

    it "counts multiple visits in a day as one daily followup" do
      multi_visit_patient = create(:patient, :hypertension, recorded_at: long_ago)

      [
        june_1, june_1, june_1,
        june_2
      ].each do |date|
        create(:bp_with_encounter, patient: multi_visit_patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, period: :day)

      Timecop.freeze(june_3) do
        expect(activity_service.follow_ups).to eq(june_1 => 1, june_2 => 1)
      end
    end
  end

  describe "bp measures" do
    it "returns bp measures for a facility" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1)

      Timecop.freeze(aug_3) do
        expect(activity_service.bp_measures).to eq(june_1 => 3, july_1 => 1, aug_1 => 2)
      end
    end

    it "returns bp measures for a facility group" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_2, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_group)

      Timecop.freeze(aug_3) do
        expect(activity_service.bp_measures).to eq(june_1 => 4, july_1 => 3, aug_1 => 4)
      end
    end

    it "can be grouped further" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_2, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_group, group: BloodPressure.arel_table[:facility_id])

      Timecop.freeze(aug_3) do
        expect(activity_service.bp_measures).to eq(
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
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, period: :day)

      Timecop.freeze(aug_3) do
        expect(activity_service.bp_measures).to include(
          june_1 => 2,
          june_2 => 1,
          july_1 => 3,
          aug_1 => 1,
          aug_2 => 1
        )

        # All other days are zeros
        other_days = activity_service.bp_measures.except(june_1, june_2, july_1, aug_1, aug_2)
        expect(other_days.values.uniq).to contain_exactly(0)
      end
    end

    it "can exclude the current period" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, include_current_period: false)

      Timecop.freeze(aug_3) do
        expect(activity_service.bp_measures).to eq(june_1 => 3, july_1 => 1)
      end
    end

    it "can return only the last N periods" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, last: 2)

      Timecop.freeze(aug_3) do
        expect(activity_service.bp_measures).to eq(july_1 => 1, aug_1 => 2)
      end
    end

    it "can return diabetes patients only" do
      # Excluded patients
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        htn_patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: htn_patient, facility: facility_1, recorded_at: date)
        create(:blood_sugar, patient: htn_patient, facility: facility_1, recorded_at: date)

        dm_patient_with_blood_sugar = create(:patient, :diabetes, recorded_at: long_ago)
        create(:blood_sugar, patient: dm_patient_with_blood_sugar, facility: facility_1, recorded_at: date)
      end

      # Included patients
      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        dm_patient_with_bp = create(:patient, :diabetes, recorded_at: long_ago)
        create(:bp_with_encounter, patient: dm_patient_with_bp, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, diagnosis: :diabetes)

      Timecop.freeze(aug_3) do
        expect(activity_service.bp_measures).to eq(june_1 => 1, july_1 => 2, aug_1 => 2)
      end
    end

    it "can return all patients" do
      [
        june_1, june_2, june_3,
        july_1,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :hypertension, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      [
        june_1,
        july_1, july_3,
        aug_1, aug_2
      ].each do |date|
        patient = create(:patient, :diabetes, recorded_at: long_ago)
        create(:bp_with_encounter, patient: patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1, diagnosis: :all)

      Timecop.freeze(aug_3) do
        expect(activity_service.bp_measures).to eq(june_1 => 4, july_1 => 3, aug_1 => 4)
      end
    end

    it "counts multiple BPs in a month as separate BPs" do
      multi_visit_patient = create(:patient, :hypertension, recorded_at: long_ago)

      [
        june_1, june_2, june_3,
        july_1
      ].each do |date|
        create(:bp_with_encounter, patient: multi_visit_patient, facility: facility_1, recorded_at: date)
      end

      activity_service = ActivityService.new(facility_1)

      Timecop.freeze(july_3) do
        expect(activity_service.bp_measures).to eq(june_1 => 3, july_1 => 1)
      end
    end
  end
end
