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
  end

  context "Behavior" do
    it_behaves_like "a record that is deletable"
  end
end
