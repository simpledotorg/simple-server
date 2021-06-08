require "rails_helper"

RSpec.describe FacilityBusinessIdentifier, type: :model do
  describe "Associations" do
    it { should belong_to(:facility) }
  end

  describe "Validations" do
    it { should validate_presence_of(:identifier) }
    it { should validate_presence_of(:identifier_type) }
    it { should validate_presence_of(:facility) }
  end
end
