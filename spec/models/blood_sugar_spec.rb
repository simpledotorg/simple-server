# frozen_string_literal: true

require "rails_helper"

RSpec.describe BloodSugar, type: :model do
  describe "Validations" do
    it_behaves_like "a record that validates device timestamps"
  end

  describe "Associations" do
    it { should belong_to(:facility).optional }
    it { should belong_to(:patient).optional }
    it { should belong_to(:user).optional }
  end

  describe "#diabetic?" do
    [{blood_sugar_type: :random, blood_sugar_value: 300},
      {blood_sugar_type: :fasting, blood_sugar_value: 200},
      {blood_sugar_type: :post_prandial, blood_sugar_value: 300},
      {blood_sugar_type: :hba1c, blood_sugar_value: 9.0}].each do |row|
      it "returns true if blood sugar is in a high state" do
        blood_sugar = create(:blood_sugar,
          blood_sugar_type: row[:blood_sugar_type],
          blood_sugar_value: row[:blood_sugar_value])
        expect(blood_sugar).to be_diabetic
      end
    end

    [{blood_sugar_type: :random, blood_sugar_value: 299},
      {blood_sugar_type: :fasting, blood_sugar_value: 199},
      {blood_sugar_type: :post_prandial, blood_sugar_value: 299},
      {blood_sugar_type: :hba1c, blood_sugar_value: 8.9}].each do |row|
      it "returns false if blood sugar is not in a high state" do
        blood_sugar = create(:blood_sugar,
          blood_sugar_type: row[:blood_sugar_type],
          blood_sugar_value: row[:blood_sugar_value])
        expect(blood_sugar).not_to be_diabetic
      end
    end
  end

  describe "Scopes" do
    let!(:fasting) { create(:blood_sugar, blood_sugar_type: :fasting) }
    let!(:random) { create(:blood_sugar, blood_sugar_type: :random) }
    let!(:post_prandial) { create(:blood_sugar, blood_sugar_type: :post_prandial) }
    let!(:hba1c) { create(:blood_sugar, blood_sugar_type: :hba1c) }

    describe ".for_v3" do
      it "only includes non hba1c blood sugars" do
        expect(BloodSugar.for_v3).not_to include(hba1c)
        expect(BloodSugar.for_v3.count).to eq 3
      end
    end

    describe ".for_sync" do
      it "includes discarded blood sugars" do
        discarded_blood_sugar = create(:blood_sugar, deleted_at: Time.now)

        expect(described_class.for_sync).to include(discarded_blood_sugar)
      end
    end
  end
end
