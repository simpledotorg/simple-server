require 'rails_helper'

RSpec.describe PhoneNumber, type: :model do
  describe "Validations" do
    it { should validate_presence_of(:created_at) }
    it { should validate_presence_of(:updated_at) }
    it { should validate_presence_of(:number) }
  end

  describe "Associations" do
    it { should have_and_belong_to_many(:patients)}
  end
end
