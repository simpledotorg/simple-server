# frozen_string_literal: true

require "rails_helper"

RSpec.describe BloodPressure, type: :model do
  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"
  end

  describe "Associations" do
    it { should belong_to(:facility).optional }
    it { should belong_to(:patient).optional }
    it { should belong_to(:user).optional }
  end

  describe "Behavior" do
    it_behaves_like "a record that is deletable"
  end

  it "has a valid encounter / observation for bp_with_encounter factory" do
    user = create(:user)
    patient = create(:patient)
    bp = create(:bp_with_encounter, user: user, patient: patient)
    bp.reload
    expect(bp.observation).to_not be nil
    expect(bp.encounter).to_not be nil
    expect(bp.observation.user).to eq(bp.user)
    expect(bp.observation.observable).to eq(bp)
    expect(bp.encounter.patient).to eq(bp.patient)
    expect(bp.encounter.observations).to contain_exactly(bp.observation)
    # This behavior is a bit confusing, but this matches what we do in Encounter#generated_encountered_on
    expect(bp.encounter.encountered_on).to eq(bp.recorded_at.in_time_zone(Period::REPORTING_TIME_ZONE).to_date)
  end

  describe "Scopes" do
    describe ".hypertensive" do
      it "only includes hypertensive BPs" do
        bp_normal = create(:blood_pressure, systolic: 120, diastolic: 80)
        bp_high_systolic = create(:blood_pressure, systolic: 140, diastolic: 80)
        bp_high_diastolic = create(:blood_pressure, systolic: 120, diastolic: 90)
        bp_high_both = create(:blood_pressure, systolic: 150, diastolic: 100)

        expect(BloodPressure.hypertensive).to include(bp_high_systolic, bp_high_diastolic, bp_high_both)
        expect(BloodPressure.hypertensive).not_to include(bp_normal)
      end
    end

    describe ".under_control" do
      it "only includes BPs under control" do
        bp_normal = create(:blood_pressure, systolic: 120, diastolic: 80)
        bp_high_systolic = create(:blood_pressure, systolic: 140, diastolic: 80)
        bp_high_diastolic = create(:blood_pressure, systolic: 120, diastolic: 90)
        bp_high_both = create(:blood_pressure, systolic: 150, diastolic: 100)

        expect(BloodPressure.under_control).to include(bp_normal)
        expect(BloodPressure.under_control).not_to include(bp_high_systolic, bp_high_diastolic, bp_high_both)
      end
    end

    describe ".for_sync" do
      it "includes discarded blood pressures" do
        discarded_bp = create(:blood_pressure, deleted_at: Time.now)

        expect(described_class.for_sync).to include(discarded_bp)
      end
    end

    describe ".for_recent_bp_log" do
      it "orders bps by date descending" do
        Timecop.freeze("1 Jul 2021 1PM UTC") do
          bp_1 = create(:blood_pressure, recorded_at: 2.day.ago)
          bp_2 = create(:blood_pressure, recorded_at: 1.day.ago)

          expect(described_class.for_recent_bp_log).to eq([bp_2, bp_1])
        end
      end

      it "orders bps by time of day ascending for BPs on the same date" do
        Timecop.freeze("1 Jul 2021 1PM UTC") do
          bp_1 = create(:blood_pressure, recorded_at: 20.minutes.ago)
          bp_2 = create(:blood_pressure, recorded_at: 10.minutes.ago)

          expect(described_class.for_recent_bp_log).to eq([bp_1, bp_2])
        end
      end

      context "respects the reporting timezone for ordering" do
        it "BPs in different days in reporting time zone but same day in UTC are ordered descending" do
          bp_1 = create(:blood_pressure, recorded_at: Time.zone.parse("1 July 2021 11:30PM IST"))
          bp_2 = create(:blood_pressure, recorded_at: Time.zone.parse("2 July 2021 12:30AM IST"))

          expect(described_class.for_recent_bp_log).to eq([bp_2, bp_1])
        end
      end
    end
  end

  context "utility methods" do
    let(:bp_normal) { create(:blood_pressure, systolic: 120, diastolic: 80) }
    let(:bp_high_systolic) { create(:blood_pressure, systolic: 140, diastolic: 80) }
    let(:bp_high_diastolic) { create(:blood_pressure, systolic: 120, diastolic: 90) }
    let(:bp_high_both) { create(:blood_pressure, systolic: 150, diastolic: 100) }

    describe "#under_control?" do
      it "returns true if both systolic and diastolic are under control" do
        expect(bp_normal).to be_under_control
      end

      it "returns false if systolic is high" do
        expect(bp_high_systolic).not_to be_under_control
      end

      it "returns false if diastolic is high" do
        expect(bp_high_diastolic).not_to be_under_control
      end

      it "returns false if both systolic and diastolic are high" do
        expect(bp_high_both).not_to be_under_control
      end
    end

    describe "#critical?" do
      [{systolic: 181, diastolic: 111},
        {systolic: 181, diastolic: 109},
        {systolic: 179, diastolic: 111}].each do |row|
        it "returns true if bp is in a critical state" do
          bp = create(:blood_pressure, systolic: row[:systolic], diastolic: row[:diastolic])
          expect(bp).to be_critical
        end
      end

      it "returns false if bp is not in a critical state" do
        bp = create(:blood_pressure, systolic: 179, diastolic: 109)
        expect(bp).not_to be_critical
      end
    end

    describe "#hypertensive?" do
      [{systolic: 140, diastolic: 80},
        {systolic: 120, diastolic: 90},
        {systolic: 180, diastolic: 120}].each do |row|
        it "returns true if bp is high" do
          bp = create(:blood_pressure, systolic: row[:systolic], diastolic: row[:diastolic])
          expect(bp).to be_hypertensive
        end
      end

      it "returns false if bp is not high" do
        bp = create(:blood_pressure, systolic: 139, diastolic: 89)
        expect(bp).not_to be_hypertensive
      end
    end

    describe "#recorded_days_ago" do
      it "returns 2 days" do
        bp_recorded_2_days_ago = create(:blood_pressure, device_created_at: 2.days.ago)

        expect(bp_recorded_2_days_ago.recorded_days_ago).to eq(2)
      end
    end

    describe "#to_s" do
      it "is systolic/diastolic" do
        expect(bp_normal.to_s).to eq("120/80")
      end
    end
  end

  context "anonymised data for blood pressures" do
    describe "anonymized_data" do
      it "correctly retrieves the anonymised data for the blood pressure" do
        blood_pressure = create(:blood_pressure)

        anonymised_data =
          {id: Hashable.hash_uuid(blood_pressure.id),
           patient_id: Hashable.hash_uuid(blood_pressure.patient_id),
           created_at: blood_pressure.created_at,
           bp_date: blood_pressure.recorded_at,
           registration_facility_name: blood_pressure.facility.name,
           user_id: Hashable.hash_uuid(blood_pressure.user.id),
           bp_systolic: blood_pressure.systolic,
           bp_diastolic: blood_pressure.diastolic}

        expect(blood_pressure.anonymized_data).to eq anonymised_data
      end
    end
  end

  context "#find_or_update_observation!" do
    let(:blood_pressure) { create(:blood_pressure, :with_encounter) }
    let!(:encounter) { blood_pressure.encounter }
    let!(:observation) { blood_pressure.observation }
    let!(:user) { blood_pressure.user }

    it "updates discarded observations also" do
      observation.discard
      blood_pressure.reload

      encounter.encountered_on = 1.year.ago
      encounter.save
      blood_pressure.find_or_update_observation!(encounter, user)

      expect(encounter.encountered_on).to eq 1.year.ago.to_date
    end
  end
end
