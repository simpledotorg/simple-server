require 'rails_helper'

RSpec.describe Address, type: :model do
  describe "Validations" do
    it {should validate_presence_of(:created_at)}
    it {should validate_presence_of(:updated_at)}
  end
end
