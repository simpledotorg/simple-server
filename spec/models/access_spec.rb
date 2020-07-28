require "rails_helper"

RSpec.describe Access, type: :model do
  describe "Validations" do
    it { is_expected.to validate_presence_of(:mode) }
  end

  describe "Associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:resource).optional }
  end
end
