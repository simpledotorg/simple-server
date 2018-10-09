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

  describe "#under_control?" do
    let(:bp) { build(:blood_pressure) }

    it "returns true if both systolic and diastolic are under control" do
      bp.systolic = 139
      bp.diastolic = 89
      expect(bp.under_control?).to eq(true)
    end

    it "returns false if systolic is high" do
      bp.systolic = 140
      bp.diastolic = 89
      expect(bp.under_control?).to eq(false)
    end

    it "returns false if diastolic is high" do
      bp.systolic = 139
      bp.diastolic = 90
      expect(bp.under_control?).to eq(false)
    end

    it "returns false if both systolic and diastolic are high" do
      bp.systolic = 150
      bp.diastolic = 100
      expect(bp.under_control?).to eq(false)
    end
  end
end
