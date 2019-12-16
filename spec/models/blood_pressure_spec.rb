require 'rails_helper'
include Hashable

RSpec.describe BloodPressure, type: :model do
  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end

  describe 'Associations' do
    it { should belong_to(:facility).optional }
    it { should belong_to(:patient).optional }
    it { should belong_to(:user).optional }
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  context "utility methods" do
    let(:bp_normal) { create(:blood_pressure, systolic: 120, diastolic: 80) }
    let(:bp_high_systolic) { create(:blood_pressure, systolic: 140, diastolic: 80) }
    let(:bp_high_diastolic) { create(:blood_pressure, systolic: 120, diastolic: 90) }
    let(:bp_high_both) { create(:blood_pressure, systolic: 150, diastolic: 100) }

    describe ".hypertensive" do
      it "only includes hypertensive BPs" do
        expect(BloodPressure.hypertensive).to include(bp_high_systolic, bp_high_diastolic, bp_high_both)
        expect(BloodPressure.hypertensive).not_to include(bp_normal)
      end
    end

    describe ".hypertensive" do
      it "only includes BPs under control" do
        expect(BloodPressure.under_control).to include(bp_normal)
        expect(BloodPressure.under_control).not_to include(bp_high_systolic, bp_high_diastolic, bp_high_both)
      end
    end

    describe "#under_control?" do
      it "returns true if both systolic and diastolic are under control" do
        expect(bp_normal.under_control?).to eq(true)
      end

      it "returns false if systolic is high" do
        expect(bp_high_systolic.under_control?).to eq(false)
      end

      it "returns false if diastolic is high" do
        expect(bp_high_diastolic.under_control?).to eq(false)
      end

      it "returns false if both systolic and diastolic are high" do
        expect(bp_high_both.under_control?).to eq(false)
      end
    end

    describe "#critical?" do
      [{ systolic: 181, diastolic: 111 },
       { systolic: 181, diastolic: 109 },
       { systolic: 179, diastolic: 111 }].each do |row|
        it "returns true if bp is in a critical state" do
          bp = create(:blood_pressure, systolic: row[:systolic], diastolic: row[:diastolic])
          expect(bp.critical?).to eq(true)
        end
      end

      it "returns false if bp is not in a critical state" do
        bp = create(:blood_pressure, systolic: 179, diastolic: 109)
        expect(bp.critical?).to eq(false)
      end
    end

    describe "#very_high?" do
      it "returns true if bp is very high" do
        bp = create(:blood_pressure, systolic: rand(160..179), diastolic: rand(100..109))
        expect(bp.very_high?).to eq(true)
      end
    end

    describe "#high?" do
      it "returns true if the bp is high" do
        bp = create(:blood_pressure, systolic: rand(140..159), diastolic: rand(90..99))
        expect(bp.high?).to eq(true)
      end
    end

    describe '#recorded_days_ago' do
      it 'returns 2 days' do
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

  context 'anonymised data for blood pressures' do
    describe 'anonymized_data' do
      it 'correctly retrieves the anonymised data for the blood pressure' do
        blood_pressure = create(:blood_pressure)

        anonymised_data =
          { id: hash_uuid(blood_pressure.id),
            patient_id: hash_uuid(blood_pressure.patient_id),
            created_at: blood_pressure.created_at,
            bp_date: blood_pressure.recorded_at,
            registration_facility_name: blood_pressure.facility.name,
            user_id: hash_uuid(blood_pressure.user.id),
            bp_systolic: blood_pressure.systolic,
            bp_diastolic: blood_pressure.diastolic
          }

        expect(blood_pressure.anonymized_data).to eq anonymised_data
      end
    end
  end
end
