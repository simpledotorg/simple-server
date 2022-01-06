# frozen_string_literal: true

require "rails_helper"

describe CallResult, type: :model do
  describe "Associations" do
    it { should belong_to(:appointment).optional }
    it { should belong_to(:user) }
  end

  context "Validations" do
    it { should validate_presence_of(:result_type) }
    it { should validate_presence_of(:appointment_id) }
    it_behaves_like "a record that validates device timestamps"
    it "validates remove_reason if result_type is :removed_from_overdue_list" do
      call_result = build(:call_result, result_type: :removed_from_overdue_list, remove_reason: nil)
      expect(call_result).to be_invalid
      expect(call_result.errors.messages).to eq({remove_reason: ["should be present if removed from overdue list"]})
    end
  end

  context "Behavior" do
    it_behaves_like "a record that is deletable"
  end
end
