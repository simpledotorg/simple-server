require 'rails_helper'

RSpec.describe BloodSugar, type: :model do
  describe 'Validations' do
    it_behaves_like 'a record that validates device timestamps'
  end

  describe 'Associations' do
    it { should belong_to(:facility).optional }
    it { should belong_to(:patient).optional }
    it { should belong_to(:user).optional }
  end

  describe '#diabetic?' do
    [{ blood_sugar_type: :random, blood_sugar_value: 300 },
     { blood_sugar_type: :fasting, blood_sugar_value: 200 },
     { blood_sugar_type: :post_prandial, blood_sugar_value: 300 }].each do |row|
      it 'returns true if blood sugar is in a high state' do
        blood_sugar = create(:blood_sugar,
                             blood_sugar_type: row[:blood_sugar_type],
                             blood_sugar_value: row[:blood_sugar_value])
        expect(blood_sugar).to be_diabetic
      end
    end

    [{ blood_sugar_type: :random, blood_sugar_value: 299 },
     { blood_sugar_type: :fasting, blood_sugar_value: 299 },
     { blood_sugar_type: :post_prandial, blood_sugar_value: 199 }].each do |row|
      it 'returns false if blood sugar is not in a high state' do
        blood_sugar = create(:blood_sugar,
                             blood_sugar_type: row[:blood_sugar_type],
                             blood_sugar_value: row[:blood_sugar_value])
        expect(blood_sugar).not_to be_diabetic
      end
    end
  end
end
