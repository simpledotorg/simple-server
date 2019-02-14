require 'rails_helper'

RSpec.describe BloodPressure, type: :model do
  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end

  describe 'Associations' do
    it { should belong_to(:facility)}
    it { should belong_to(:patient)}
    it { should belong_to(:user)}
  end

  describe 'Behavior' do
    it_behaves_like 'a record that is deletable'
  end

  context "utility methods" do
    let(:bp_normal)         { create(:blood_pressure, systolic: 120, diastolic: 80) }
    let(:bp_high_systolic)  { create(:blood_pressure, systolic: 140, diastolic: 80) }
    let(:bp_high_diastolic) { create(:blood_pressure, systolic: 120, diastolic: 90) }
    let(:bp_high_both)      { create(:blood_pressure, systolic: 150, diastolic: 100) }

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

    describe '#recorded_days_ago' do
      it 'returns 2 days' do
        bp_recorded_2_days_ago = create(:blood_pressure, device_created_at: 2.days.ago)

        expect(bp_recorded_2_days_ago.recorded_days_ago).to eq(2)
      end
    end
  end
end
